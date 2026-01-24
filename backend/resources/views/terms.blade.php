<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Terms of Service - Texme</title>
    <style>
        body {
            font-family: sans-serif;
            line-height: 1.6;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            color: #333;
        }

        h1 {
            color: #2c3e50;
        }

        h2 {
            color: #34495e;
            margin-top: 20px;
        }

        ul {
            margin-bottom: 15px;
        }

        li {
            margin-bottom: 5px;
        }
    </style>
</head>

<body>
    @if(isset($content) && !empty($content))
        {!! $content !!}
    @else
        <h1>Terms of Service</h1>
        <p>Last updated: January 24, 2026</p>

        <p>Please read these Terms of Service ("Terms") carefully before using the Texme mobile application (the "Service")
            operated by Texme ("us", "we", or "our").</p>

        <h2>1. Acceptance of Terms</h2>
        <p>By accessing or using the Service, you agree to be bound by these Terms. If you disagree with any part of the
            terms, then you may not access the Service.</p>

        <h2>2. User Accounts</h2>
        <p>When you create an account with us, you must provide information that is accurate, complete, and current at all
            times. Failure to do so constitutes a breach of the Terms, which may result in immediate termination of your
            account on our Service.</p>

        <h2>3. Content and Conduct</h2>
        <p>You are responsible for the content you post and your interactions with other users. You agree not to upload,
            post, or transmit any content that is unlawful, harmful, threatening, abusive, harassing, defamatory, obscene,
            or otherwise objectionable.</p>
        <p>We reserve the right to ban users who violate these guidelines.</p>

        <h2>4. Termination</h2>
        <p>We may terminate or suspend access to our Service immediately, without prior notice or liability, for any reason
            whatsoever, including without limitation if you breach the Terms.</p>

        <h2>5. Changes</h2>
        <p>We reserve the right, at our sole discretion, to modify or replace these Terms at any time. If a revision is
            material, we will try to provide at least 30 days' notice prior to any new terms taking effect.</p>

        <h2>6. Contact Us</h2>
        <p>If you have any questions about these Terms, please contact us at:</p>
        <p>Email: support@texme.app</p>
    @endif
</body>

</html>