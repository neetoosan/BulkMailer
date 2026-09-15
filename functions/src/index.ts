import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { processEmailQueue } from "./processEmailQueue";
import { handleUnsubscribe } from "./unsubscribeHandler";
import { onCampaignSend } from "./sendEmailBatch";

admin.initializeApp();

// Scheduled: process email queue every minute
export const processQueue = onSchedule("every 1 minutes", processEmailQueue);

// HTTP: handle unsubscribe links in emails
export const handleUnsubscribeHttp = functions.https.onRequest(handleUnsubscribe);

// Firestore trigger: when campaign status changes to "sending"
export const onCampaignStatusChange = functions.firestore
  .document("users/{userId}/campaigns/{campaignId}")
  .onUpdate(onCampaignSend);