---
tags: javascript, firebase, backend
summary: When you delete a document in Firestore, its subcollections and their documents are not automatically recursively deleted. Here is a simple Cloud Function that takes care of it.
---

# Clean up Firestore and Storage when deleting a document
When you delete a document in Firestore, its subcollections and their documents are not automatically recursively deleted. Here is a simple Cloud Function that takes care of it. As a bonus, it also deletes all stored files in Firebase Storage in a folder with the same name as the document id.

``` javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();
const client = require('firebase-tools');
const bucket = admin.storage().bucket('gs://your-bucket.appspot.com');

exports.onDeleteCampaign = functions.firestore.document('campaigns/{campaignId}').onDelete((snap, context) => {
  const campaignId = context.params.campaignId;

  // Delete all nested sub collections
  const prom1 = client.firestore.delete(`campaigns/${campaignId}`, {
    project: process.env.GCLOUD_PROJECT,
    recursive: true,
    yes: true
  }); 

  // And delete any uploaded images
  const prom2 = deleteFiles(campaignId);

  return Promise.all([prom1, prom2]);
});

async function deleteFiles(campaignId) {
  const options = {
    prefix: `campaign/${campaignId}`,
  };

  const [files] = await bucket.getFiles(options);
  const deletePromises = files.map(file => file.delete());
  return Promise.all(deletePromises);
}
```

For example in my case all images for a campaign are stored as `campaign/{campaignId}/subfolder/filename`, and that makes it easy to delete all images using the Cloud Function above.
