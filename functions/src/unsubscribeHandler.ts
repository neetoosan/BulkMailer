import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import { Request, Response } from "express";

const db = admin.firestore();

/**
 * HTTP function to handle unsubscribe link clicks.
 * URL: /handleUnsubscribeHttp?uid=xxx&listId=xxx&contactId=xxx
 */
export const handleUnsubscribe = async (req: Request, res: Response): Promise<void> => {
  const { uid, listId, contactId } = req.query;

  if (!uid || !listId || !contactId) {
    res.status(400).send("Invalid unsubscribe link");
    return;
  }

  try {
    await db
      .collection("users")
      .doc(uid as string)
      .collection("lists")
      .doc(listId as string)
      .collection("subscribers")
      .doc(contactId as string)
      .update({
        status: "unsubscribed",
        unsubscribedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    // Update list count
    await db
      .collection("users")
      .doc(uid as string)
      .collection("lists")
      .doc(listId as string)
      .update({
        count: admin.firestore.FieldValue.increment(-1),
      });

    functions.logger.info(`Unsubscribed contact ${contactId} from list ${listId}`);

    // Return a nice unsubscribe confirmation page
    res.status(200).send(`
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Unsubscribed</title>
        <style>
          body { font-family: Arial, sans-serif; background: #0F1117; color: white;
                 display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
          .card { background: #1A1D27; border-radius: 16px; padding: 48px; text-align: center; max-width: 480px; }
          h2 { color: #6C63FF; margin-bottom: 16px; }
          p { color: rgba(255,255,255,0.6); line-height: 1.6; }
        </style>
      </head>
      <body>
        <div class="card">
          <h2>? You have been unsubscribed</h2>
          <p>You will no longer receive emails from this sender. If this was a mistake, please contact the sender directly.</p>
        </div>
      </body>
      </html>
    `);
  } catch (error) {
    functions.logger.error("Error unsubscribing:", error);
    res.status(500).send("An error occurred. Please try again.");
  }
};
