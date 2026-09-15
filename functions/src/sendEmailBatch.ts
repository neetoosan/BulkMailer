import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

const db = admin.firestore();

/**
 * Triggered when a campaign document is updated.
 * If status changes to "sending", create individual email_jobs.
 */
export const onCampaignSend = async (
  change: functions.Change<functions.firestore.DocumentSnapshot>,
  context: functions.EventContext
) => {
  const before = change.before.data();
  const after = change.after.data();

  if (!before || !after) return;

  // Only trigger when status changes to "sending"
  if (before.status === after.status) return;
  if (after.status !== "sending") return;

  const { userId, campaignId } = context.params;
  const { listId, templateId, subject } = after;

  functions.logger.info(
    `Campaign ${campaignId} for user ${userId} started sending`
  );

  try {
    // Get the template
    const templateSnap = await db
      .collection("users")
      .doc(userId)
      .collection("templates")
      .doc(templateId)
      .get();

    if (!templateSnap.exists) {
      functions.logger.error("Template not found:", templateId);
      await change.after.ref.update({ status: "failed" });
      return;
    }

    // Get all active subscribers from the list
    const subscribersSnap = await db
      .collection("users")
      .doc(userId)
      .collection("lists")
      .doc(listId)
      .collection("subscribers")
      .where("status", "==", "active")
      .get();

    if (subscribersSnap.empty) {
      functions.logger.warn("No active subscribers in list:", listId);
      await change.after.ref.update({ status: "sent" });
      return;
    }

    // Create email_jobs in batches
    const BATCH_SIZE = 500;
    const subscribers = subscribersSnap.docs;
    let jobsCreated = 0;

    for (let i = 0; i < subscribers.length; i += BATCH_SIZE) {
      const chunk = subscribers.slice(i, i + BATCH_SIZE);
      const batch = db.batch();

      for (const sub of chunk) {
        const subData = sub.data();
        const jobRef = db.collection("email_jobs").doc();
        batch.set(jobRef, {
          campaignId,
          userId,
          listId,
          contactId: sub.id,
          recipientEmail: subData.email,
          recipientFirstName: subData.firstName || "",
          recipientLastName: subData.lastName || "",
          templateId,
          subject,
          status: "pending",
          retries: 0,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        jobsCreated++;
      }

      await batch.commit();
    }

    // Update campaign stats
    await change.after.ref.update({
      "stats.total": jobsCreated,
    });

    functions.logger.info(`Created ${jobsCreated} email jobs for campaign ${campaignId}`);
  } catch (error) {
    functions.logger.error("Error creating email jobs:", error);
    await change.after.ref.update({ status: "failed" });
  }
};
