# In order to send an email using the Console, just follow this link

https://aws.amazon.com/getting-started/hands-on/send-an-email/

---

- To send test emails and manage activity:

  - **SES Console**

- To send bulk emails:

  - **SES SMTP** (Not intersed now)
  - **SES API**

- To send bulk email with SES API we have 3 solutions:

  - `Make direct HTTPS requests` - This is the most advanced method, because you have to manually handle authentication and signing of your requests, and then manually construct the requests.

  - `Use an AWS SDK` - AWS SDKs make it easy to access the APIs for several AWS services, including Amazon SES. When you use an SDK, it takes care of authentication, request signing, retry logic, error handling, and other low-level functions so that you can focus on building applications that delight your customers.

  - `Use the CLI`

<br/>

Amazon SES API provides two different ways for you to send an email, depending on how much control you want over the composition of the email message:

- **Formatted** - Amazon SES composes and sends a properly formatted email message. You need only supply `From:` and `To:` addresses, a `subject`, and a `message body`. Amazon SES takes care of all the rest.
- **Raw** - You **manually compose** and send an email message, specifying your own email `headers` and `MIME types`. If you're experienced in formatting your own email, the raw interface gives you more control over the composition of your message.
