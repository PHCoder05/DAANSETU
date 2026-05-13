/**
 * Mock Government API Service
 * Simulates cross-checking NGO registration numbers with the NGO Darpan API.
 */

class GovApiService {
  /**
   * Verify an NGO's registration details against government databases.
   * @param {string} registrationNumber The registration number provided by the NGO.
   * @param {string} ngoName The name of the NGO.
   * @returns {Promise<Object>} Verification result
   */
  static async verifyNgoRegistration(registrationNumber, ngoName) {
    // Simulate network latency (500ms - 1500ms)
    const delay = Math.floor(Math.random() * 1000) + 500;
    await new Promise(resolve => setTimeout(resolve, delay));

    if (!registrationNumber) {
      return {
        verified: false,
        message: 'No registration number provided.',
      };
    }

    const regUpper = registrationNumber.toUpperCase().trim();

    // Mock logic: Valid if it starts with 'NGO-' or 'GOV-'
    const isValidFormat = regUpper.startsWith('NGO-') || regUpper.startsWith('GOV-');

    if (isValidFormat) {
      // Simulate a high match score for valid formats
      const matchScore = Math.floor(Math.random() * 10) + 90; // 90% - 99%
      return {
        verified: true,
        message: 'Registration details match government records.',
        data: {
          registeredName: ngoName.toUpperCase(),
          matchScore: `${matchScore}%`,
          verifiedAt: new Date().toISOString(),
          darpanId: `DL/${new Date().getFullYear()}/${Math.floor(Math.random() * 100000)}`
        }
      };
    }

    return {
      verified: false,
      message: 'Registration number not found in NGO Darpan database.',
      data: null
    };
  }
}

module.exports = GovApiService;
