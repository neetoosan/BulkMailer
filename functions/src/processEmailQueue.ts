import { ScheduledEvent } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import { google } from "googleapis";

const db = admin.firestore();
const MAX_EMAILS_PER_RUN = 10;

/**
 * Scheduled function that runs every minute.
 * Picks up pending email jobs and sends them via Gmail API.
 */
export const processEmailQueue = async (_: ScheduledEvent) => {
  // Get pending jobs
  const pendingJobs = await db
    .collection("email_jobs")
    .where("status", "==", "pending")
    .orderBy("createdAt", "asc")
    .limit(MAX_EMAILS_PER_RUN)
    .get();

  if (pendingJobs.empty) {
    functions.logger.info("No pending email jobs");
    return;
  }

  functions.logger.info(`Processing ${pendingJobs.size} email jobs`);

  for (const jobDoc of pendingJobs.docs) {
    const job = jobDoc.data();

    // Mark as processing
    await jobDoc.ref.update({ status: "processing" });

    try {
      // Get user profile (for OAuth tokens)
      const userDoc = await db.collection("users").doc(job.userId).get();
      const userData = userDoc.data();

      if (!userData?.gmailAccessToken) {
        functions.logger.warn(`No Gmail token for user ${job.userId}`);
        await jobDoc.ref.update({ status: "failed", error: "No Gmail token" });
        continue;
      }

      // Get template
      const templateDoc = await db
        .collection("users")
        .doc(job.userId)
        .collection("templates")
        .doc(job.templateId)
        .get();

      const template = templateDoc.data();
      if (!template) {
        await jobDoc.ref.update({ status: "failed", error: "Template not found" });
        continue;
      }

      // Personalize content
      const fields: Record<string, string> = {
        first_name: job.recipientFirstName || "",
        last_name: job.recipientLastName || "",
        full_name: `${job.recipientFirstName} ${job.recipientLastName}`.trim(),
        email: job.recipientEmail,
      };

      let htmlBody = template.htmlBody || "";
      let plainText = template.plainText || "";
      let subject = job.subject || template.subject || "";

      Object.entries(fields).forEach(([key, value]) => {
        htmlBody = htmlBody.replaceAll(`{{${key}}}`, value);
        plainText = plainText.replaceAll(`{{${key}}}`, value);
        subject = subject.replaceAll(`{{${key}}}`, value);
      });

      // Inject unsubscribe URL
      const unsubscribeUrl = `https://us-central1-flix-mailer.cloudfunctions.net/handleUnsubscribeHttp?uid=${job.userId}&listId=${job.listId}&contactId=${job.contactId}`;
      htmlBody = htmlBody.replaceAll("{{unsubscribe_url}}", unsubscribeUrl);

      // Send via Gmail API
      const auth = new google.auth.OAuth2();
      auth.setCredentials({ access_token: userData.gmailAccessToken });

      const gmail = google.gmail({ version: "v1", auth });

      const fromName = userData.displayName || "BulkMailer";
      const fromEmail = userData.email;
      const toName = `${job.recipientFirstName} ${job.recipientLastName}`.trim();

      const rawEmail = buildRawEmail({
        from: `"${fromName}" <${fromEmail}>`,
        to: toName ? `"${toName}" <${job.recipientEmail}>` : job.recipientEmail,
        subject,
        htmlBody,
        plainText,
        unsubscribeUrl,
      });

      const encodedEmail = Buffer.from(rawEmail)
        .toString("base64")
        .replace(/\+/g, "-")
        .replace(/\//g, "_")
        .replace(/=/g, "");

      await gmail.users.messages.send({
        userId: "me",
        requestBody: { raw: encodedEmail },
      });

      // Mark as sent
      await jobDoc.ref.update({ status: "sent", sentAt: admin.firestore.FieldValue.serverTimestamp() });

      // Increment campaign sent count
      await db
        .collection("users")
        .doc(job.userId)
        .collection("campaigns")
        .doc(job.campaignId)
        .update({ "stats.sent": admin.firestore.FieldValue.increment(1) });

    } catch (error: unknown) {
      functions.logger.error(`Failed to send email job ${jobDoc.id}:`, error);
      const retries = (job.retries || 0) + 1;
      await jobDoc.ref.update({
        status: retries >= 3 ? "failed" : "pending",
        retries,
        error: String(error),
      });

      // Increment failed count if permanently failed
      if ((job.retries || 0) + 1 >= 3) {
        await db
          .collection("users")
          .doc(job.userId)
          .collection("campaigns")
          .doc(job.campaignId)
          .update({ "stats.failed": admin.firestore.FieldValue.increment(1) });
      }
    }
  }

  // Check if all jobs for each campaign are done and update status
  const campaignIds = [...new Set(pendingJobs.docs.map((d) => d.data().campaignId as string))];
  for (const campaignId of campaignIds) {
    const remaining = await db
      .collection("email_jobs")
      .where("campaignId", "==", campaignId)
      .where("status", "in", ["pending", "processing"])
      .limit(1)
      .get();

    if (remaining.empty) {
      // All jobs complete — find campaign user
      const jobData = pendingJobs.docs.find(
        (d) => d.data().campaignId === campaignId
      )?.data();
      if (jobData) {
        await db
          .collection("users")
          .doc(jobData.userId)
          .collection("campaigns")
          .doc(campaignId)
          .update({ status: "sent", sentAt: admin.firestore.FieldValue.serverTimestamp() });
      }
    }
  }
};

function buildRawEmail(opts: {
  from: string;
  to: string;
  subject: string;
  htmlBody: string;
  plainText: string;
  unsubscribeUrl?: string;
}): string {
  const boundary = `boundary_${Date.now()}`;
  const lines: string[] = [
    `From: ${opts.from}`,
    `To: ${opts.to}`,
    `Subject: ${opts.subject}`,
    "MIME-Version: 1.0",
    `Content-Type: multipart/alternative; boundary="${boundary}"`,
  ];

  if (opts.unsubscribeUrl) {
    lines.push(`List-Unsubscribe: <${opts.unsubscribeUrl}>`);
    lines.push("List-Unsubscribe-Post: List-Unsubscribe=One-Click");
  }

  lines.push(
    "",
    `--${boundary}`,
    'Content-Type: text/plain; charset="UTF-8"',
    "",
    opts.plainText,
    "",
    `--${boundary}`,
    'Content-Type: text/html; charset="UTF-8"',
    "",
    opts.htmlBody,
    "",
    `--${boundary}--`
  );

  return lines.join("\r\n");
}
