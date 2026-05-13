const axios = require('axios');

const email = 'pankajhadole4@gmail.com';
const password = '@Pankaj24';
const baseURL = 'http://localhost:5000/api/v1';

const donations = [
  {
    title: '50kg Rice and Lentils',
    description: 'Freshly bought bags of rice and lentils for an orphanage or shelter. Stored properly and completely sealed.',
    category: 'food',
    condition: 'new',
    priority: 'high',
    quantity: 50,
    unit: 'kg',
    images: ['https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&q=80&w=1000'],
    pickupLocation: {
      address: 'Near Main Square, Pune, Maharashtra',
      lat: 18.6232,
      lng: 73.7488
    },
    pickupInstructions: 'Call me when you reach the gate. Guard will let you in.'
  },
  {
    title: 'Winter Clothes Collection',
    description: 'Around 20 warm jackets, sweaters, and blankets. Gently used but clean and in great condition. Perfect for the upcoming winter.',
    category: 'clothes',
    condition: 'good',
    priority: 'normal',
    quantity: 20,
    unit: 'pieces',
    images: ['https://images.unsplash.com/photo-1489987707023-afc824781ef1?auto=format&fit=crop&q=80&w=1000'],
    pickupLocation: {
      address: 'MG Road, Pune',
      lat: 18.5204,
      lng: 73.8567
    },
    pickupInstructions: 'Pick up after 5 PM on weekdays.'
  },
  {
    title: 'Medical Supplies & First Aid Kits',
    description: 'Unopened bandages, antiseptics, masks, and basic non-prescription medical supplies suitable for community clinics.',
    category: 'medical',
    condition: 'new',
    priority: 'urgent',
    quantity: 5,
    unit: 'boxes',
    images: ['https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&q=80&w=1000'],
    pickupLocation: {
      address: 'Kalyani Nagar, Pune',
      lat: 18.5484,
      lng: 73.9023
    },
    pickupInstructions: 'Available anytime at the reception desk.'
  },
  {
    title: 'Textbooks and Story Books',
    description: 'Syllabus books for 5th to 8th grade along with an assortment of children story books. Excellent condition.',
    category: 'books',
    condition: 'good',
    priority: 'low',
    quantity: 45,
    unit: 'items',
    images: ['https://images.unsplash.com/photo-1524995997946-a1c2e315a42f?auto=format&fit=crop&q=80&w=1000'],
    pickupLocation: {
      address: 'Aundh, Pune',
      lat: 18.5614,
      lng: 73.8056
    },
    pickupInstructions: 'Please bring a carton to carry them.'
  }
];

async function seed() {
  try {
    console.log(`Logging in as ${email}...`);
    const loginRes = await axios.post(`${baseURL}/auth/login`, {
      email,
      password
    });
    
    console.log('Login successful! Extracting token...');
    const token = loginRes.data.data.accessToken;
    console.log('Login successful! Seeding donations...');

    for (let i = 0; i < donations.length; i++) {
      const payload = donations[i];
      console.log(`Creating donation: ${payload.title}`);
      
      const res = await axios.post(`${baseURL}/donations`, payload, {
        headers: {
          Authorization: `Bearer ${token}`
        }
      });
      console.log(` -> Success! ID: ${res.data.data._id}`);
    }

    console.log('✅ Seeding completed successfully!');
  } catch (error) {
    console.error('❌ Seeding failed:');
    if (error.response) {
      console.error(error.response.data);
    } else {
      console.error(error.message);
    }
  }
}

seed();
