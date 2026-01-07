## Backend environment setup (Laravel)

Create a file named `.env` inside the `backend/` folder.

Use this as a starting template:

```env
APP_NAME=Texme
APP_ENV=local
APP_KEY=
APP_DEBUG=true
APP_URL=http://localhost:8000

LOG_CHANNEL=stack
LOG_LEVEL=debug

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=texme
DB_USERNAME=root
DB_PASSWORD=

SESSION_DRIVER=file
QUEUE_CONNECTION=database
CACHE_STORE=file

# OTP Provider: msg91 | 2factor | twilio | log
OTP_PROVIDER=log
OTP_API_KEY=
OTP_SENDER_ID=TEXME
MSG91_TEMPLATE_ID=
TWILIO_SID=
TWILIO_TOKEN=
TWILIO_FROM=

# Payment Gateways
RAZORPAY_KEY_ID=
RAZORPAY_KEY_SECRET=
RAZORPAY_WEBHOOK_SECRET=

PAYU_MERCHANT_KEY=
PAYU_SALT=
PAYU_MODE=test

CASHFREE_APP_ID=
CASHFREE_SECRET_KEY=
CASHFREE_WEBHOOK_SECRET=
CASHFREE_MODE=test

# Firebase Admin SDK (backend push)
# Place your service account JSON at: backend/firebase-credentials.json
FIREBASE_SERVER_KEY=
```

Notes:
- OTP testing: in **non-production**, the API accepts the test OTP `011011`.
- FCM sending from backend requires `firebase-credentials.json` (service account JSON).
- For local testing, payment webhooks will not work unless your backend is reachable from the internet (e.g. ngrok).


