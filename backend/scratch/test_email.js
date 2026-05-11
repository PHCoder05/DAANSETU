require('dotenv').config();
const nodemailer = require('nodemailer');

async function testEmail() {
  console.log('📧 Testing Brevo SMTP...');
  
  const transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: process.env.SMTP_PORT,
    secure: process.env.SMTP_PORT == 465, // true for 465, false for other ports
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS,
    },
  });

  try {
    const info = await transporter.sendMail({
      from: process.env.EMAIL_FROM,
      to: "pankajhadole4@gmail.com",
      subject: "Daansetu SMTP Test",
      text: "If you are reading this, your Brevo SMTP is working perfectly!",
      html: "<b>If you are reading this, your Brevo SMTP is working perfectly!</b>",
    });

    console.log("✅ Message sent: %s", info.messageId);
  } catch (error) {
    console.error("❌ Error sending email:", error);
  }
}

testEmail();
