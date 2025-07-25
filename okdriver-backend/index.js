const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors'); // Add this line
const otpRoutes = require('./routes/DriverAuth/otpRoutes');

dotenv.config();
const app = express();

app.use(cors()); // Add this line
app.use(express.json());
app.use('/api/driver', otpRoutes);
app.use('/api/drivers', require('./routes/DriverAuth/driverRegistration'));

app.get('/', (req, res) => {
  res.send('Ok Driver Backend Services is Running Successfully');
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Server started on port ${PORT}`);
});
