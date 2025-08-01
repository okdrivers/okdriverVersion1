const express = require('express');
const router = express.Router();
const { sendOTP, verifyOTP } = require('../../controller/DriverAuth/otpController');

router.post('/send-otp', sendOTP);
router.post('/verify-otp', verifyOTP);

module.exports = router;
