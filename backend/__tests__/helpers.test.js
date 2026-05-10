const { ObjectId } = require('mongodb');
const { buildDonationFilter, sanitizeUser } = require('../utils/helpers');

describe('Security and Privacy Helpers', () => {
  // MOCK DATA
  const mockUser = {
      _id: new ObjectId(),
      name: 'John Donor',
      email: 'john@example.com',
      role: 'donor',
      phone: '1234567890',
      address: '123 Private St',
      location: { lat: 10, lng: 20, address: '123 Private St' }
  };

  const mockNGO = {
      _id: new ObjectId(),
      name: 'Helping Hand NGO',
      email: 'ngo@example.com',
      role: 'ngo',
      phone: '9876543210',
      ngoDetails: {
          registrationNumber: 'NGO123',
          description: 'Testing NGO'
      }
  };

  const mockAdmin = {
      _id: new ObjectId(),
      name: 'Admin User',
      role: 'admin'
  };

  describe('buildDonationFilter', () => {
    it('should default to available status for public requests', () => {
      const filter = buildDonationFilter({});
      expect(filter.status).toBe('available');
    });

    it('should override claimed status request with available for public', () => {
      const filter = buildDonationFilter({ status: 'claimed' });
      expect(filter.status).toBe('available');
    });

    it('should allow NGO to query their own claimed donations', () => {
      const filter = buildDonationFilter({ status: 'claimed' }, mockNGO._id.toString(), 'ngo');
      expect(filter.status).toBe('claimed');
      expect(filter.claimedBy).toBe(mockNGO._id.toString());
    });

    it('should allow Admin to query any claimed donations', () => {
      const filter = buildDonationFilter({ status: 'claimed' }, mockAdmin._id.toString(), 'admin');
      expect(filter.status).toBe('claimed');
      expect(filter.claimedBy).toBeUndefined();
    });
  });

  describe('sanitizeUser', () => {
    it('should hide sensitive info when public views a donor', () => {
      const sanitized = sanitizeUser(mockUser);
      expect(sanitized.phone).toBeUndefined();
      expect(sanitized.email).toBeUndefined();
      expect(sanitized.address).toBeUndefined();
      expect(sanitized.location).toBeUndefined();
      expect(sanitized.name).toBe('John Donor');
    });

    it('should show sensitive info when owner views their own profile', () => {
      const sanitized = sanitizeUser(mockUser, { userId: mockUser._id.toString(), role: 'donor' });
      expect(sanitized.phone).toBe('1234567890');
      expect(sanitized.email).toBe('john@example.com');
      expect(sanitized.location).toBeDefined();
    });

    it('should hide sensitive info when public views an NGO', () => {
      const sanitized = sanitizeUser(mockNGO);
      expect(sanitized.phone).toBeUndefined();
      expect(sanitized.email).toBeUndefined();
      expect(sanitized.ngoDetails.registrationNumber).toBeUndefined();
      expect(sanitized.ngoDetails.description).toBe('Testing NGO'); // safe info
    });

    it('should show sensitive info when Admin views an NGO', () => {
      const sanitized = sanitizeUser(mockNGO, { userId: mockAdmin._id.toString(), role: 'admin' });
      expect(sanitized.phone).toBe('9876543210');
      expect(sanitized.email).toBe('ngo@example.com');
      expect(sanitized.ngoDetails.registrationNumber).toBe('NGO123');
    });
  });
});
