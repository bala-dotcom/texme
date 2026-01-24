<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Privacy Policy - Texme</title>
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
        <h1>Privacy Policy</h1>
        <p>Last updated: January 24, 2026</p>

        <p>Texme ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we
            collect, use, disclosure, and safeguard your information when you access our mobile application (the
            "Application").</p>

        <h2>1. Information We Collect</h2>

        <h3>a. Personal Data</h3>
        <p>We may collect personally identifiable information, such as your name, email address, phone number, and gender
            when you register with the Application.</p>

        <h3>b. Media and Audio</h3>
        <p>Our Application allows users to share photos and send voice messages. We collect and store these files to provide
            the core functionality of the service. These are stored securely on our servers.</p>

        <h3>c. Device Information</h3>
        <p>We may request access or permission to certain system features from your mobile device, including your camera,
            microphone, and storage.</p>

        <h2>2. Use of Your Information</h2>
        <p>We use the information we collect to:</p>
        <ul>
            <li>Create and manage your account.</li>
            <li>Facilitate text, voice, and video communication between users.</li>
            <li>Process transactions (if applicable).</li>
            <li>Monitor and prevent fraudulent or abusive activity.</li>
            <li>Enforce our terms of service and community guidelines.</li>
        </ul>

        <h2>3. Disclosure of Your Information</h2>
        <p>We do not sell, trade, or otherwise transfer to outside parties your Personally Identifiable Information unless
            we provide you with advance notice, except as described below.</p>
        <ul>
            <li><strong>Service Providers:</strong> We may share information with third parties that perform services for us
                or on our behalf, such as payment processing and data hosting.</li>
            <li><strong>Legal Obligations:</strong> We may disclose information if required to do so by law or in response
                to valid requests by public authorities.</li>
        </ul>

        <h2>4. Data Security</h2>
        <p>We use administrative, technical, and physical security measures to help protect your personal information. While
            we have taken reasonable steps to secure the personal information you provide to us, please be aware that
            despite our efforts, no security measures are perfect or impenetrable.</p>

        <h2>5. Deletion of Data</h2>
        <p>You have the right to request the deletion of your account and personal data. You can do this directly within the
            App settings by navigating to <strong>Profile > Delete Account</strong>, or by contacting us.</p>

        <h2>6. Contact Us</h2>
        <p>If you have questions or comments about this Privacy Policy, please contact us at:</p>
        <p>Email: support@texme.app</p>
    @endif
</body>

</html>