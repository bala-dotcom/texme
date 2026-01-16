# DLT Registration Guide for Texme SMS/OTP

## What is DLT?
DLT (Distributed Ledger Technology) is a TRAI (Telecom Regulatory Authority of India) mandate requiring all commercial SMS senders to register their:
- Company/Entity details
- Sender IDs (Headers)
- Message Templates

This ensures transparency and prevents spam SMS in India.

---

## 📋 Prerequisites Checklist

Before starting DLT registration, gather these documents:

### For Company/Business:
- [ ] Company Registration Certificate
- [ ] GST Certificate (GSTIN)
- [ ] PAN Card of the company
- [ ] Address Proof (Electricity Bill/Rent Agreement)
- [ ] Authorized Signatory's ID Proof (Aadhaar/PAN)
- [ ] Letter of Authorization (if applicable)

### For Individual/Proprietorship:
- [ ] PAN Card
- [ ] Aadhaar Card
- [ ] Business Registration Certificate (if applicable)
- [ ] GST Certificate (if registered)
- [ ] Address Proof

---

## 🚀 Step-by-Step Registration Process

### Step 1: Choose a DLT Platform

Pick ONE of these platforms (all are TRAI-approved):

1. **Jio Trueconnect** (Recommended - Fastest approval)
   - Website: https://trueconnect.jio.com
   - Approval Time: 1-2 days

2. **Airtel DLT**
   - Website: https://www.airtel.in/dlt/
   - Approval Time: 2-3 days

3. **Vodafone Idea DLT**
   - Website: https://www.vilpower.in/
   - Approval Time: 2-4 days

4. **BSNL DLT**
   - Website: https://www.ucc-bsnl.co.in/
   - Approval Time: 3-5 days

### Step 2: Register Your Entity

1. Go to your chosen DLT platform
2. Click "Register" or "Sign Up"
3. Choose entity type:
   - Individual
   - Proprietorship
   - Partnership
   - Private Limited
   - Public Limited
   - Government
   - Others

4. Fill in details:
   - Entity Name: **Texme** (or your registered business name)
   - Entity Type: (as applicable)
   - PAN Number
   - GST Number (if applicable)
   - Registered Address
   - Contact Details

5. Upload documents
6. Submit for verification
7. Wait for approval (1-5 days depending on platform)

### Step 3: Register Sender ID (Header)

Once your entity is approved:

1. Login to DLT platform
2. Go to "Header" or "Sender ID" section
3. Click "Add New Header"
4. Enter details:
   - **Header Name**: `TEXMEO` (6 characters, alphanumeric)
     - Note: Must be related to your brand/company name
     - Can't use generic names like "OTP", "VERIFY", etc.
   - **Header Type**: Transactional
   - **Telemarketer**: (leave blank if not applicable)

5. Submit for approval
6. Wait for approval (usually same day to 2 days)

### Step 4: Register OTP Template

After header approval:

1. Go to "Templates" or "Content Templates" section
2. Click "Add New Template"
3. Fill in template details:
   - **Template Type**: Transactional - OTP
   - **Template Name**: Texme OTP Verification
   - **Template Content**:
     ```
     Your Texme verification code is {#var#}. Valid for 10 minutes. Do not share with anyone.
     ```
   - **Variables**: 
     - {#var#} = OTP code
   - **Category**: Transactional
   - **Header**: Select "TEXMEO" (your approved header)

4. Submit for approval
5. Wait for TRAI approval (1-3 days)

### Step 5: Link DLT with MSG91

Once template is approved:

1. Get from DLT platform:
   - **Entity ID** (PE-ID)
   - **Header** (e.g., TEXMEO)
   - **Template ID** (e.g., 1207xxxxxxxxx)

2. Login to MSG91 dashboard: https://control.msg91.com
3. Go to Settings → DLT
4. Enter your DLT details:
   - Entity ID
   - Header/Sender ID
   - Link template IDs

5. Save settings

### Step 6: Update Backend Configuration

Update your server's `.env` file:

```bash
# Connect to server
ssh root@72.61.249.79

# Edit .env
nano /var/www/api.texme.online/.env

# Update these values:
OTP_SENDER_ID=TEXMEO
MSG91_TEMPLATE_ID=<your_approved_template_id>
MSG91_ENTITY_ID=<your_entity_id>

# Save and exit (Ctrl+X, Y, Enter)

# Clear cache
cd /var/www/api.texme.online
php artisan config:clear
php artisan cache:clear

# Restart services
systemctl restart php8.2-fpm
systemctl restart nginx
```

---

## 📝 Sample Template Content

Here are approved template examples for OTP:

### Template 1 (Recommended):
```
Your Texme verification code is {#var#}. Valid for 10 minutes. Do not share with anyone.
```

### Template 2:
```
{#var#} is your Texme OTP. This OTP is valid for 10 minutes. Please do not share this OTP with anyone.
```

### Template 3:
```
Dear user, your Texme OTP is {#var#}. Valid for 10 minutes. - TEXMEO
```

---

## ⏱️ Timeline Expectations

| Step | Time Required |
|------|---------------|
| Entity Registration | 1-5 business days |
| Header/Sender ID Approval | Same day - 2 days |
| Template Approval | 1-3 business days |
| MSG91 Configuration | Immediate |
| **Total Time** | **3-10 business days** |

---

## 💰 Costs

- **DLT Registration**: FREE (on all platforms)
- **MSG91 SMS Credits**: Pay as you go
  - OTP SMS: ₹0.10 - ₹0.20 per SMS (approximately)

---

## ❓ Common Issues & Solutions

### Issue: Entity Registration Rejected
**Solution**: 
- Ensure all documents are clear and valid
- Check that PAN/GST numbers match registered business name
- Use proper business address (not residential)

### Issue: Header Rejected
**Solution**:
- Use 6-character alphanumeric header
- Must relate to your brand name
- Avoid generic terms

### Issue: Template Rejected
**Solution**:
- Don't use promotional language in transactional template
- Must include clear opt-out mechanism for promotional messages
- For OTP, keep it simple and informative
- Don't add URLs or promotional content

---

## 🎯 Quick Start Recommendation

**For Fastest Setup (Jio Trueconnect):**

1. **Today**: Register entity on https://trueconnect.jio.com
2. **Day 2-3**: Once approved, register header "TEXMEO"
3. **Day 3-4**: Once header approved, register OTP template
4. **Day 5-6**: Link DLT IDs to MSG91
5. **Day 6**: Update server config and test!

---

## 📞 Support Contacts

- **Jio Trueconnect**: support@jiodlt.in
- **Airtel DLT**: dlt.support@airtel.com
- **MSG91 Support**: support@msg91.com

---

## ✅ Post-Registration Checklist

After DLT approval:
- [ ] Entity ID received
- [ ] Header/Sender ID approved: TEXMEO
- [ ] Template ID received
- [ ] DLT IDs linked in MSG91 dashboard
- [ ] Server .env updated with correct template ID
- [ ] Backend cache cleared
- [ ] Test OTP sent successfully
- [ ] SMS received on mobile phone

---

## 🔄 What to Do Right Now

**Immediate Action Items:**

1. **Gather Documents** (30 minutes)
   - Get PAN, Aadhaar, business docs ready
   - Scan or take clear photos

2. **Choose DLT Platform** (5 minutes)
   - Recommended: Jio Trueconnect (fastest)
   - Create account

3. **Start Entity Registration** (20 minutes)
   - Fill form carefully
   - Upload documents
   - Submit

4. **Wait for Approval** (1-5 days)
   - Monitor email for updates
   - Check DLT portal daily

---

## Meanwhile: Use Test OTP

While waiting for DLT approval, use test OTP `011011` for development:
- Works immediately
- No SMS costs
- Perfect for testing all features

Once DLT is approved, switch to real OTP by updating the template ID.

---

**Need help at any step? Let me know!**
