# find-my-pet
Cross-platform mobile application using Googles Flutter Technology.

## Overview
FindMyPet is a cross-platform mobile application built using Googles Flutter technology. It utilises the Dart programming language to help build expressive and flexible UI that gives full native performance on either mobile platform. The aim of which is to give users the ability to post details of lost, spotted or found animals in their area.

Push notifications are a very important aspect of this project as it will have the biggest impact on helping to return pets home quickly and safely. With push notifications, as soon as a user creates a post about their missing a pet, all users within a 10-kilometre radius will receive a push notification.

The backend of this project was built using a multitude of Firebase tools:
- The Firebase authentication service was used to create and authenticate credentials for users. 
- Cloud Firestore was used as the projects database of choice. Arguably the projects goal becomes more effective as the userbase grows, making a scalable but low-cost database an important factor.
- Firebase Storage tool is also used within this project in order to store media data, namely images. 
- Firebase Functions were also used in order to automatically run backend code in response to predefined triggers. For the purposes of this project the functions, when triggered, send push notifications related to new posts in the user’s area or when someone comments on their post.

There is be a range of features, such as push notifications if an animal is reported lost in a user’s area, searching for posts based on location and communicating with other users via comments.

## Screenshots
### Authentication
<img src="https://user-images.githubusercontent.com/57196168/81421792-f5298300-9149-11ea-9652-e25b4efff7a7.png" alt="App Image" height=600 width="280"> <img src="https://user-images.githubusercontent.com/57196168/81422205-90baf380-914a-11ea-9d0f-f40a7f1894de.png" alt="App Image" height=600 width="280"> 
### Posts Overview
<img src="https://user-images.githubusercontent.com/57196168/81422394-cd86ea80-914a-11ea-89cf-2ff6876bb2ae.png" alt="App Image" height=600 width="280"> <img src="https://user-images.githubusercontent.com/57196168/81422489-ee4f4000-914a-11ea-99ae-07e8701cf78e.png" alt="App Image" height=600 width="280"> 
### Post and Comments
<img src="https://user-images.githubusercontent.com/57196168/81422559-03c46a00-914b-11ea-8279-0c1d78c9ba4e.png" alt="App Image" height=600 width="280"> <img src="https://user-images.githubusercontent.com/57196168/81422574-0921b480-914b-11ea-8634-8aa98189b841.png" alt="App Image" height=600 width="280"> 
### Map
<img src="https://user-images.githubusercontent.com/57196168/81422742-4ede7d00-914b-11ea-8ff3-1b0daeaf89e9.png" alt="App Image" height=600 width="280"> <img src="https://user-images.githubusercontent.com/57196168/81422750-51d96d80-914b-11ea-849a-9e9721e369bb.png" alt="App Image" height=600 width="280"> 
### Add Post
<img src="https://user-images.githubusercontent.com/57196168/81422863-7d5c5800-914b-11ea-84aa-4d40901a83ad.png" alt="App Image" height=600 width="280"> <img src="https://user-images.githubusercontent.com/57196168/81422871-80574880-914b-11ea-99d0-7a362615f672.png" alt="App Image" height=600 width="280"> 
### Search and Profile
<img src="https://user-images.githubusercontent.com/57196168/81422944-9f55da80-914b-11ea-9140-6867243c8aee.png" alt="App Image" height=600 width="280"> <img src="https://user-images.githubusercontent.com/57196168/81422863-7d5c5800-914b-11ea-84aa-4d40901a83ad.png" alt="App Image" height=600 width="280">
### Push Notification
<img src="https://user-images.githubusercontent.com/57196168/81425559-b7c7f400-914f-11ea-9380-2028f659489d.png" alt="App Image" height=600 width="280"> 
