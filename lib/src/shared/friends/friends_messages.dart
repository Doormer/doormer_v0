/// What the app says about friends, in its own words. The API's error bodies
/// are plain text written for developers, so the app never shows them: each
/// status it expects has its words here, and every call has its own words
/// for anything else.
abstract final class FriendsMessages {
  // A status any friends call can answer with.
  static const turnedOff = 'Friends is turned off for your account.';
  static const doneTooOftenToday =
      "You've done that a lot today. Try again tomorrow.";

  /// The words for each status any friends call can answer with.
  static const anyCallRefusals = {
    403: turnedOff,
    429: doneTooOftenToday,
  };

  // A status one call answers with.
  static const pickDifferentNickname = 'Please pick a different nickname.';
  static const codeNotFound =
      "We couldn't find that code. Check it and try again.";
  static const youHaveHundredFriends =
      'You have 100 friends. Remove one to add another.';
  static const yourOwnCode = "That's your own code.";
  static const requestExpired = 'That request has expired.';
  static const oneOfYouHasHundredFriends =
      'One of you already has 100 friends.';
  static const studentNotFound = "We couldn't find that student.";
  static const friendNotFound = "We couldn't find that friend.";

  // Anything else, by call.
  static const couldNotLoadFriends = "We couldn't load your friends.";
  static const couldNotSaveProfile =
      "We couldn't save your nickname and picture. Try again.";
  static const couldNotLoadPictures = "We couldn't load your cards.";
  static const couldNotResetCode =
      "We couldn't make you a new code. Try again.";
  static const couldNotFind = "We couldn't look up that code. Try again.";
  static const couldNotSendRequest = "We couldn't send the request. Try again.";
  static const couldNotAcceptRequest =
      "We couldn't accept the request. Try again.";
  static const couldNotDeclineRequest =
      "We couldn't decline the request. Try again.";
  static const couldNotRemoveFriend =
      "We couldn't remove that friend. Try again.";
  static const couldNotBlock = "We couldn't block that student. Try again.";
  static const couldNotUnblock = "We couldn't unblock that student. Try again.";
  static const couldNotLoadBlocked =
      "We couldn't load the students you've blocked.";
  static const couldNotReport = "We couldn't send the report. Try again.";
  static const couldNotLoadFriendCards =
      "We couldn't load your friend's cards.";

  /// A friend's collection that failed to load, such as "We couldn't load
  /// Sam's cards.". Without a nickname, "your friend's".
  static String couldNotLoadCardsOf(String? nickname) => nickname == null
      ? couldNotLoadFriendCards
      : "We couldn't load $nickname's cards.";

  // An error that isn't a Failure, which the app didn't expect.
  static const somethingWentWrong = 'Something went wrong. Try again.';

  // When the browser refuses to copy.
  static const couldNotCopy =
      "We couldn't copy that. Select the text and copy it yourself.";
}
