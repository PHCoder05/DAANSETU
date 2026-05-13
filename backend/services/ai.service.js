const { GoogleGenerativeAI } = require("@google/generative-ai");

class AIService {
  constructor() {
    const apiKey = process.env.GEMINI_API_KEY;
    if (apiKey) {
      this.genAI = new GoogleGenerativeAI(apiKey);
    }
  }

  async analyzeDonationImage(base64Image) {
    if (!this.genAI) {
      // Fallback/Mock response if no API key is provided
      console.warn("GEMINI_API_KEY not found. Returning mock analysis.");
      return this._getMockAnalysis();
    }

    try {
      const model = this.genAI.getGenerativeModel({ model: "gemini-2.5-flash" });
      
      const prompt = `Analyze this donation image and return a JSON object with:
      - title (concise and catchy)
      - description (brief and helpful)
      - category (choose exactly one from: food, clothes, books, medical, electronics, furniture)
      - estimatedQuantity (number only)
      - suggestedUnit (one of: pieces, kg, boxes, bags, bottles, items)
      - urgency (one of: high, normal, low)
      - beneficiaryImpact (short emotional sentence about who it helps)
      
      Return ONLY the JSON object.`;

      // Remove data:image/...;base64, prefix
      const imageData = base64Image.split(",")[1] || base64Image;

      const result = await model.generateContent([
        prompt,
        {
          inlineData: {
            data: imageData,
            mimeType: "image/jpeg"
          }
        }
      ]);

      const response = await result.response;
      const text = response.text();
      
      // Extract JSON from text (sometimes Gemini wraps it in ```json ... ```)
      const jsonMatch = text.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        return JSON.parse(jsonMatch[0]);
      }
      
      throw new Error("Failed to parse AI response");
    } catch (error) {
      if (error.status) {
        console.error(`AI Analysis Error [${error.status}]: ${error.statusText || error.message}`);
      } else {
        console.error("AI Analysis Error:", error.message || error);
      }
      return this._getMockAnalysis();
    }
  }

  _getMockAnalysis() {
    return {
      title: "Clothing Bundle for Donation",
      description: "A mixed collection of items in good wearable condition.",
      category: "clothes",
      estimatedQuantity: 5,
      suggestedUnit: "pieces",
      urgency: "normal",
      beneficiaryImpact: "This donation will provide essential warmth and dignity to those in need."
    };
  }

  async parseVoiceSearch(query) {
    if (!this.genAI) {
      return { category: null, location: null, searchTerm: query, onlyVerified: false };
    }

    try {
      const model = this.genAI.getGenerativeModel({ model: "gemini-2.5-flash" });
      const prompt = `Convert this natural language donation query into a search filter JSON object.
      Query: "${query}"
      
      Extract:
      - category (choose exactly one from: food, clothes, books, medical, electronics, furniture, or null if not mentioned)
      - location (extract city or area name, or null)
      - searchTerm (cleaned search keyword for NGO name, or null)
      - onlyVerified (boolean, true if user asks for verified/trusted/approved NGOs)
      
      Return ONLY the JSON object. 
      Example: {"category": "food", "location": "Mumbai", "searchTerm": null, "onlyVerified": false}`;

      const result = await model.generateContent(prompt);
      const response = await result.response;
      const text = response.text();
      
      const jsonMatch = text.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        return JSON.parse(jsonMatch[0]);
      }
    } catch (error) {
      console.error("AI Voice Search Parse Error:", error);
      return { category: null, location: null, searchTerm: query, onlyVerified: false };
    }
  }

  async parseVoiceDonation(query) {
    if (!this.genAI) {
      return { title: query, description: query, category: 'general', quantity: 1, unit: 'items', condition: 'good' };
    }

    try {
      const model = this.genAI.getGenerativeModel({ model: "gemini-2.5-flash" });
      const prompt = `Convert this natural language donation description into a structured JSON object for a donation form.
      Description: "${query}"
      
      Extract:
      - title (concise, catchy, e.g., "5 Fresh Pizza Boxes")
      - description (more detail if available)
      - category (choose exactly one from: food, clothes, books, medical, electronics, furniture)
      - quantity (number only)
      - unit (one of: pieces, kg, boxes, bags, bottles, items)
      - condition (one of: new, good, fair)
      - priority (one of: urgent, normal)
      
      Return ONLY the JSON object.`;

      const result = await model.generateContent(prompt);
      const response = await result.response;
      const text = response.text();
      
      const jsonMatch = text.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        return JSON.parse(jsonMatch[0]);
      }
      return { title: query, description: query, category: 'general', quantity: 1, unit: 'items', condition: 'good' };
    } catch (error) {
      console.error("AI Voice Donation Parse Error:", error);
      return { title: query, description: query, category: 'general', quantity: 1, unit: 'items', condition: 'good' };
    }
  }

  async chat(message, history = []) {
    if (!this.genAI) {
      return "I'm sorry, my AI brain is currently disconnected. Please check your API key.";
    }

    try {
      const model = this.genAI.getGenerativeModel({ model: "gemini-2.5-flash" });
      const chat = model.startChat({
        history: history.map(msg => ({
          role: msg.role === 'user' ? 'user' : 'model',
          parts: [{ text: msg.content }]
        })),
        generationConfig: {
          maxOutputTokens: 500,
        },
      });

      const systemPrompt = `You are "Setu AI", the AI Assistant for Daansetu, a premium donation platform. 
      You help donors find NGOs, explain how impact points work, and provide guidance on what to donate.
      Be helpful, warm, and professional. 
      If asked about specific NGOs, suggest categories like food, clothes, books, medical, electronics, or furniture.
      Daansetu uses a "Seeing is Believing" approach with impact stories.
      The current user's message is: "${message}"`;

      const result = await chat.sendMessage(systemPrompt);
      const response = await result.response;
      return response.text();
    } catch (error) {
      console.error("AI Chat Error:", error);
      return "I encountered a glitch in my neural network. Could you please repeat that?";
    }
  }

  async recommendNGOs(db, donationDetails, userLat, userLng) {
    try {
      // 1. Fetch all verified NGOs with their needs
      const ngos = await db.collection('users').find({
        role: 'ngo',
        'ngoDetails.verificationStatus': 'verified'
      }).toArray();

      if (!ngos.length) return [];

      const donationCategory = donationDetails.category?.toLowerCase();
      
      // 2. Score each NGO
      const scoredNgos = ngos.map(ngo => {
        let score = 0;
        let matchingReason = "";

        // Category match (0-50 pts)
        const categories = (ngo.ngoDetails?.categories || []).map(c => c.toLowerCase());
        if (categories.includes(donationCategory)) {
          score += 40;
          matchingReason = `Specializes in ${donationCategory} donations. `;
        }

        // Needs/Wishlist match (0-30 pts)
        const needs = ngo.ngoDetails?.needs || [];
        const specificNeed = needs.find(n => n.category?.toLowerCase() === donationCategory);
        if (specificNeed) {
          const priorityBonus = specificNeed.priority === 'high' ? 30 : 15;
          score += priorityBonus;
          matchingReason += `Urgent need for ${donationCategory} reported. `;
        }

        // Proximity score (0-20 pts)
        if (userLat && userLng && ngo.location?.coordinates) {
          const [ngoLng, ngoLat] = ngo.location.coordinates;
          const distance = this._calculateDistance(userLat, userLng, ngoLat, ngoLng);
          
          if (distance < 5) score += 20; // < 5km
          else if (distance < 15) score += 10; // < 15km
          else if (distance < 30) score += 5; // < 30km
        }

        return {
          _id: ngo._id,
          name: ngo.name,
          profileImage: ngo.profileImage,
          location: ngo.location,
          matchScore: score,
          matchingReason: matchingReason || "A trusted NGO serving the community.",
          needs: ngo.ngoDetails?.needs || []
        };
      });

      // 3. Sort by score and return top 3
      return scoredNgos
        .filter(n => n.matchScore > 0)
        .sort((a, b) => b.matchScore - a.matchScore)
        .slice(0, 3);

    } catch (error) {
      console.error("AI Recommendation Error:", error);
      return [];
    }
  }

  _calculateDistance(lat1, lon1, lat2, lon2) {
    const R = 6371; // km
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLon = (lon2 - lon1) * Math.PI / 180;
    const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
              Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
              Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }
}

module.exports = new AIService();
