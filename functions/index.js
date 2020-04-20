const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp(functions.config().firebase);
var GeohashDistance = require('geohash-distance');

//Function to display notifications for new comments on a users post
exports.onCreateActivityFeedItem = functions.firestore
    .document('/feed/{userId}/comments/{activityFeedItem}')
    .onCreate(async (snapshot, context) => {
        //When a feed item is added run this function
        console.log('Activity Feed Item Cerated', snapshot.data());

        //Get the user connected to the feed
        const userId = context.params.userId;

        const userRef = admin.firestore().doc(`users/${userId}`);
        const doc = await userRef.get();

        //Check if user has a notification token. Send if they do
        const androidNotificationToken = doc.data().androidNotificationToken;
        if (androidNotificationToken) {
            //send notification
            sendNotification(androidNotificationToken, snapshot.data());
        } else {
            console.log("No token for user, notification could not be sent");
        }

        function sendNotification(androidNotificationToken, activityFeedItem) {
            //Body of the notification message
            const body = `${activityFeedItem.displayName} replied: ${activityFeedItem.commentData}`;

            //Create message for push notification
            const message = {
                notification: { body: body },
                //To just be sent to this person
                token: androidNotificationToken,
                data: { recipient: userId },
            };

            //send message with firebase admin
            admin.messaging().send(message).then(response => {
                console.log("Sent Message", response);
            }).catch(error => { console.log("Error", error); })
        }
    })

//Function to display notifications to users within a 10km radius of the posts location
exports.onCreatePost = functions.firestore
    .document('/posts/{postId}')
    .onCreate(async (postSnap, context) => {
        //When a post is added run this function
        console.log('New Post Created', postSnap.data());

        var postLoc = postSnap.data().position.geohash;
        var userRef = admin.firestore().collection(`users`);
        userRef.get().then(snapshot => {
            //For each user, get their location and check if they are within the set radius of the post
            snapshot.forEach(doc => {
                var userLoc = doc.data().position.geohash;
                var distance = GeohashDistance.inKm(userLoc, postLoc);
                //If conditionals are met, send notification
                if (distance < 10 && postSnap.data().petStatus != "found" && postSnap.data().petStatus != "spotted" && postSnap.data().ownerId != doc.data().id) {
                    if (doc.data().androidNotificationToken) {
                        //send notification
                        sendPostNotification(doc.data().androidNotificationToken, doc.data().id, postSnap.data());
                    } else {
                        console.log("No token for user, notification could not be sent");
                    }
                }
                else {
                    console.log("Further than 15km");
                }

            });
        });

        function sendPostNotification(androidNotificationToken, id, postInformation) {

            const body = `A pet has gone missing nearby. Please keep an eye out, it's name is ${postInformation.title}.`;

            //Create message for push notification
            const message = {
                notification: { body: body, image: postInformation.imageUrl },
                token: androidNotificationToken,
                data: { recipient: id }
            };
            //send message with firebase admin
            admin.messaging().send(message).then(response => {
                console.log("Sent Message for post", response);
            }).catch(error => { console.log("Error", error); })
        }
    }
    )


