import 'package:flutter_markdown/flutter_markdown.dart';

class AgreementText {
  static const termsOfUse = Markdown(
    data: """
These terms are the agreement between you and Doormer when you use our website and app. Please read them with a parent or guardian if you're under 18.

**Last updated:** 7 November 2026

## In short

- Use Doormer to learn.
- Follow your school's rules.
- Be kind to other students.
- AI answers can be wrong.
- Quarks and cards have no cash value.
- You keep your photos.

## Using Doormer

By using Doormer, you agree to these terms. Doormer is for learners of all ages. If you're under 16, you need a parent's or guardian's OK to use it.

Doormer is for personal, non-commercial use.

## Your account

Use accurate details when you create an account. Keep your password private. One account is for one person. Tell us if you think someone else has used your account without permission.

## Acceptable use

When you use Doormer, do not:

- break the law;
- upload other people's personal information or anything offensive, harmful or unrelated to schoolwork;
- try to break, overload, scrape, copy or reverse-engineer Doormer, or use bots;
- get around limits or security;
- resell or redistribute Doormer.

## Friends and sharing

Friends let students see each other's nicknames, pictures and cards, and share solved questions with each other. When you use friends, don't:

- choose a nickname that's unkind, or that pretends to be someone else;
- bully, threaten, embarrass or pressure anyone;
- share anything offensive or harmful, or anyone's personal information.

Only share questions you're happy for your friends to see. You can block or report another student at any time, and the Doormer team reviews reports. When these rules are broken, we may reset a nickname to “Student” or turn friends off for an account.

## Learning and academic integrity

Doormer is a study aid. Follow your school's and exam board's rules. Don't hand in Doormer's work as your own where that is not allowed.

You are responsible for how you use solutions.

## Your photos and content

You keep ownership of your photos and content. You give Doormer permission to store and process them, including with our AI provider, to provide and improve the service.

Only upload material you're allowed to use for your own study.

## AI answers can be wrong

Doormer checks its answers, but AI answers can still be wrong. Doormer is not professional advice. Check important work with your teacher.

## Quarks and cards

Quarks and cards are virtual items for fun, earned in the app. They have no cash value and can't be sold, traded or transferred for money.

We may adjust balances to fix mistakes. We may also change or end the collection, giving notice where reasonable.

## Ads and a free service

Doormer is free. Ads may appear while photos are solved. If we ever add paid features, we'll tell you first and nothing will be charged without your agreement.

## Beta, changes and availability

Doormer is in beta. Features can change. We can't promise it will always be available or error-free.

## Our content

Doormer's software, design, text, card art and brand belong to Doormer or its licensors. They are for personal use only.

## Our responsibility to you

To the extent the law allows, we're not liable for indirect loss, or loss from relying on an answer. Nothing in these terms limits rights you have under consumer law that can't be excluded, including the New Zealand Consumer Guarantees Act 1993 and the Australian Consumer Law.

## Ending your use

You can stop using Doormer any time and ask us to delete your account. We may suspend or close accounts that break these terms.

## Changes to these terms

We'll update the date above when these terms change. We'll tell you about significant changes. Continuing to use Doormer means you accept the changed terms.

## Contact

Email doormerapp@gmail.com.
""",
    selectable: true,
  );

  static const privacyPolicy = Markdown(
    data: """
This policy explains what information Doormer collects, why, and the choices you have. We've written it to be read by students and parents.

**Last updated:** 7 November 2026

## In short

- We collect what we need to solve and save your questions, and to run friends and sharing.
- Photos go to Microsoft Azure's AI service to be solved.
- Friends see your nickname, picture and cards, and only the questions you share with them. No other student sees your email address.
- We don't sell personal information.
- Every ad request is tagged for child treatment, so ads aren't based on your browsing.
- You can ask to see, correct or delete your information.

## Who we are

Doormer (“we”, “us”) runs the Doormer website and app. You can contact us at doormerapp@gmail.com.

## Information we collect

**Account details.** Your email address, and your password, which we store only in a protected form. If you sign in with Google, Google confirms your email address to us, and that's all we keep from Google.

**Question photos and solutions.** The question photos you upload, and the solutions, steps, diagrams, topics and methods Doormer creates.

**Learning activity.** Questions you've solved and saved, answers you've opened, your quark balance and history, and your card collection.

**Daily limits.** How many photos you send and questions are solved each day, and how often you look up friend codes, so we can apply the app's limits.

**Friends.** If you set up friends, we keep:

- the nickname and picture you choose (a card you own, or the first letter of your nickname)
- your friend code
- when you agreed that friends may see your nickname, picture and cards
- your friends, and when you became friends
- the friend requests you send and receive, whether they came from a friend code or an invite link, and how they were answered
- the students you've blocked

**Shared questions.** When you share a solved question, we keep which friends you shared it with and when.

**Reports.** When you report a student, we keep who made the report, who it's about, the reason, any note you add, their nickname at the time, and the shared question if the report is about one.

**Job-matching details.** Earlier versions of the app showed new accounts a form from Doormer's old job-matching service, asking for a first name, last name, phone number, a CV and job preferences, such as roles and industries. If you filled it in, we keep what you entered, including the CV. You can ask us to delete it.

**Messages and technical information.** Messages you send us. Our servers also collect technical information as they run, including IP address, browser and device type, pages requested, times and error logs.

## How we use it

We use this information to run your account and sign you in, read and solve your questions, keep them in Saved, keep quarks and cards working, run friends and sharing, apply daily limits, review reports and keep students safe, respond to messages, keep Doormer secure, fix problems, show the in-app ad that keeps Doormer free, and meet legal obligations.

We don't sell personal information.

## What other students can see

- **Students who enter your friend code or open your invite link** in the app see your nickname and picture, so they know they're adding the right person.
- **Students you send a friend request to, or get one from,** see your nickname and picture.
- **Your friends** see your nickname, picture and card collection.
- **Friends you share a question with** see its photo and full solution, and that it came from you. They don't see who else it's shared with. Questions you don't share stay private.

Sharing ends when you stop sharing a question, remove it from Saved, or remove or block the friend. A friend can also remove a question you shared from their list. When sharing ends, the friend can't open the question any more. Links to photos stop working after 24 hours, so a copied link doesn't keep working.

Blocking is private: the student you block isn't told. Blocking ends your friendship and any sharing between you, and stops their friend requests reaching you.

The Doormer team reviews reports. The student you report isn't told. We may turn off friends for an account, for example after a report or when a parent asks.

## How your photos are solved

Photos and question text are processed by Microsoft's Azure OpenAI Service to read and solve the question. They're stored in Microsoft Azure so you can see them again in Saved, and so friends you share them with can see them.

Under Microsoft's terms for this service, the data we send is not used to train OpenAI's models.

## Ads and cookies

Website pages, including home, guides, about and legal pages, show no ads and set no cookies. In the app, while a photo is being solved, you may see one ad from Google AdSense.

Google's standard notice for sites that show its ads: third-party vendors, including Google, use cookies to serve ads based on a user's prior visits to a website or to other websites, and Google's use of advertising cookies enables it and its partners to serve ads based on visits to a website and/or other sites on the internet.

On Doormer, that kind of advertising is switched off. Doormer tags every ad request for child treatment, which turns off ads based on browsing history (personalised ads) and remarketing. Google may still use cookies or similar technology for things like limiting how often an ad is shown, reporting and preventing fraud.

You can opt out of personalised advertising in Google's Ads Settings at adssettings.google.com, and opt out of some third-party vendors' cookies for personalised advertising at aboutads.info. You can read how Google uses information from sites or apps that use its services at policies.google.com/technologies/partner-sites.

Doormer's own cookies are two sign-in cookies that keep you signed in. One lasts until you close your browser, the other up to 30 days. They're needed for the app to work. If you open a friend's invite link before signing in, the app keeps its invite code in your browser for up to 7 days, so the invite can open once you sign in. Doormer uses no analytics or advertising trackers of its own.

## Who we share it with

We share information with service providers who run Doormer for us: Microsoft for Azure hosting, storage and the AI service, and Google for Google sign-in and ads in the app.

We may disclose information if the law requires it, to protect people's safety, or as part of a sale or reorganisation of Doormer, with this policy still applying. We don't sell personal information.

## Where it's stored and how we protect it

Information is stored with Microsoft Azure, which may be in data centres outside New Zealand and Australia. Connections use HTTPS. Azure encrypts stored data by default. Access is limited to people who need it.

No system is completely secure. Tell us if you think your account is at risk.

## How long we keep it

We keep information while your account is open and as long as needed for the purposes above. When sharing ends, we delete the record of that share. When you ask us to delete your account, we delete or de-identify your information unless the law requires us to keep it.

## Students and parents

Doormer is for learners of all ages. If you're under 16, you need a parent's or guardian's OK to use Doormer. Parents and guardians can contact us to see, correct or delete their child's information, or to have friends turned off for their child's account.

## Your choices and rights

In the app, you can change your nickname and picture, reset your friend code, stop sharing a question, and remove, block or unblock other students at any time.

You can ask to access or correct your personal information under the New Zealand Privacy Act 2020 or the Australian Privacy Act 1988. You can also ask us to delete your account. Email doormerapp@gmail.com.

If you're unhappy with our response, you can contact New Zealand's Office of the Privacy Commissioner (privacy.org.nz) or the Office of the Australian Information Commissioner (oaic.gov.au).

## Changes to this policy

We'll update the date above when this policy changes. For significant changes, we'll tell you in the app or by email.

## Contact us

Email doormerapp@gmail.com. Please never send us your password.
""",
    selectable: true,
  );
}
