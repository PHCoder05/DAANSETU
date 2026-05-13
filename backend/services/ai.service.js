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
      console.warn("GEMINI_API_KEY not found. Returning mock analysis.");
      return this._getMockAnalysis();
    }

    try {
      const model = this.genAI.getGenerativeModel({ model: "gemini-2.0-flash" });
      
      const prompt = `Analyze this donation image for the Daansetu platform.
      Return a JSON object with:
      - title (concise and catchy)
      - description (detailed but brief)
      - category (exactly one: food, clothes, books, medical, electronics, furniture, or 'other')
      - estimatedQuantity (number)
      - suggestedUnit (pieces, kg, boxes, bags, bottles, items)
      - urgency (high, normal, low)
      - beneficiaryImpact (emotional sentence)
      - isSafe (boolean, false if the image contains weapons, drugs, explicit content, or non-donatable trash)
      - safetyReason (string, explain if isSafe is false, otherwise null)
      
      Return ONLY the JSON object.`;

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
      
      const jsonMatch = text.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        const parsed = JSON.parse(jsonMatch[0]);
        // Add a "Confidence Score" simulation based on parsed data completeness
        parsed.confidenceScore = parsed.title && parsed.category ? 0.95 : 0.7;
        return parsed;
      }
      
      throw new Error("Failed to parse AI response");
    } catch (error) {
      console.error("AI Analysis Error:", error.message);
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

  async chat(message, history = [], userId = null) {
    if (!this.genAI) {
      return "I'm sorry, my AI brain is currently disconnected. Please check your API key.";
    }

    try {
      const { getDB } = require('../config/db');
      const db = getDB();
      
      let contextStr = "";
      
      // 1. Fetch User Context if userId is provided
      if (userId) {
        const user = await db.collection('users').findOne({ _id: userId });
        if (user) {
          contextStr += `User Profile: Name: ${user.name}, Role: ${user.role}, Impact Score: ${user.impactScore || 0}. `;
          
          // 2. Fetch Recent Donations (limit 3)
          const recentDonations = await db.collection('donations')
            .find({ userId: userId })
            .sort({ createdAt: -1 })
            .limit(3)
            .toArray();
            
          if (recentDonations.length > 0) {
            contextStr += `Recent Donations: ${recentDonations.map(d => `${d.title} (${d.status})`).join(", ")}. `;
          }
        }
      }

      // 3. Fetch Urgent NGO Needs (limit 5)
      const urgentNgos = await db.collection('users')
        .find({ role: 'ngo', 'ngoDetails.needs': { $exists: true, $not: { $size: 0 } } })
        .limit(5)
        .toArray();
      
      if (urgentNgos.length > 0) {
        const needsSummary = urgentNgos.map(ngo => {
          const topNeed = ngo.ngoDetails.needs[0];
          return `${ngo.name} needs ${topNeed.category} (${topNeed.priority} priority)`;
        }).join("; ");
        contextStr += `Urgent NGO Needs: ${needsSummary}. `;
      }

      const model = this.genAI.getGenerativeModel({ model: "gemini-2.0-flash" });
      const chat = model.startChat({
        history: history.map(msg => ({
          role: msg.role === 'user' ? 'user' : 'model',
          parts: [{ text: msg.content }]
        })),
        generationConfig: {
          maxOutputTokens: 500,
        },
      });

      const systemPrompt = `You are "Setu AI", the advanced RAG-powered AI Assistant for Daansetu.
      Your goal is to help donors and NGOs make a real impact.
      
      LIVE CONTEXT FROM DATABASE:
      ${contextStr || "No specific user context available."}
      
      STRICT GUIDELINES:
      - Use the context above to answer user questions personally. 
      - If they ask "What did I donate recently?", look at their "Recent Donations".
      - If they ask "Who needs help?", mention the "Urgent NGO Needs".
      - Be warm, professional, and impact-focused.
      - Keep responses concise (under 3 sentences unless asked for more).
      
      User's current message: "${message}"`;

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
      const ngos = await db.collection('users').find({
        role: 'ngo',
        'ngoDetails.verificationStatus': 'verified'
      }).toArray();

      if (!ngos.length) return [];

      const donationCategory = (donationDetails.category || "general").toLowerCase();
      
      // 1. Initial Filtering & Scoring (Heuristics)
      const initialCandidates = ngos.map(ngo => {
        let score = 0;
        const categories = (ngo.ngoDetails?.categories || []).map(c => c.toLowerCase());
        if (categories.includes(donationCategory)) score += 40;

        if (userLat && userLng && ngo.location?.coordinates) {
          const [ngoLng, ngoLat] = ngo.location.coordinates;
          const distance = this._calculateDistance(userLat, userLng, ngoLat, ngoLng);
          if (distance < 10) score += 20;
          else if (distance < 30) score += 10;
        }

        return { ...ngo, initialScore: score };
      }).sort((a, b) => b.initialScore - a.initialScore).slice(0, 5);

      // 2. LLM-Powered Semantic Refinement
      if (this.genAI && initialCandidates.length > 0) {
        const model = this.genAI.getGenerativeModel({ model: "gemini-2.0-flash" });
        
        const ngoDataForPrompt = initialCandidates.map((ngo, idx) => 
          `${idx + 1}. ${ngo.name}: ${ngo.ngoDetails?.description || "No description"}. Needs: ${(ngo.ngoDetails?.needs || []).map(n => n.category).join(", ")}`
        ).join("\n");

        const prompt = `Rank these 5 NGOs based on their suitability for this donation.
        Donation: ${donationDetails.title} (Category: ${donationCategory}, Description: ${donationDetails.description})
        
        NGO Candidates:
        ${ngoDataForPrompt}
        
        Return a JSON array of objects with:
        - ngoIndex (1-5)
        - semanticMatchScore (0-100)
        - matchingReason (One catchy sentence explaining the specific synergy)
        
        Order by suitability. Return ONLY the JSON array.`;

        try {
          const result = await model.generateContent(prompt);
          const response = await result.response;
          const text = response.text();
          const jsonMatch = text.match(/\[[\s\S]*\]/);
          
          if (jsonMatch) {
            const aiRankings = JSON.parse(jsonMatch[0]);
            return aiRankings.map(rank => {
              const ngo = initialCandidates[rank.ngoIndex - 1];
              return {
                _id: ngo._id,
                name: ngo.name,
                profileImage: ngo.profileImage,
                location: ngo.location,
                matchScore: rank.semanticMatchScore,
                matchingReason: rank.matchingReason,
                needs: ngo.ngoDetails?.needs || []
              };
            });
          }
        } catch (llmError) {
          console.warn("LLM Matching failed, falling back to heuristics:", llmError.message);
        }
      }

      // Fallback to basic scoring if LLM fails
      return initialCandidates.map(ngo => ({
        _id: ngo._id,
        name: ngo.name,
        profileImage: ngo.profileImage,
        location: ngo.location,
        matchScore: ngo.initialScore,
        matchingReason: `A trusted NGO matching the ${donationCategory} category.`,
        needs: ngo.ngoDetails?.needs || []
      })).slice(0, 3);

    } catch (error) {
      console.error("AI Recommendation Error:", error);
      return [];
    }
  }

  async analyzeImpactStory(content, base64Images = []) {
    if (!this.genAI) return { refinedContent: content, impactScore: 50, summary: "Story received." };

    try {
      const model = this.genAI.getGenerativeModel({ model: "gemini-2.0-flash" });
      
      let prompt = `Analyze this NGO impact story for the Daansetu platform.
      Story Content: "${content}"
      
      Generate a JSON object with:
      - refinedTitle (compelling and professional)
      - refinedContent (professionally edited version of the content)
      - summary (one-sentence summary for a notification)
      - impactScore (0-100, how clearly does this show real-world impact?)
      - emotionalSentiment (positive, neutral, heart-touching)
      
      Return ONLY the JSON object.`;

      const parts = [prompt];
      for (const img of base64Images.slice(0, 2)) {
        const imageData = img.split(",")[1] || img;
        parts.push({
          inlineData: {
            data: imageData,
            mimeType: "image/jpeg"
          }
        });
      }

      const result = await model.generateContent(parts);
      const response = await result.response;
      const text = response.text();
      const jsonMatch = text.match(/\{[\s\S]*\}/);
      
      if (jsonMatch) return JSON.parse(jsonMatch[0]);
      return { refinedContent: content, impactScore: 50, summary: "Impact recorded." };
    } catch (error) {
      console.error("AI Story Analysis Error:", error);
      return { refinedContent: content, impactScore: 50, summary: "Impact recorded." };
    }
  }

  async getAdminAnalytics(db) {
    try {
      // 1. Aggregate Donation Stats (last 30 days)
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

      const donationStats = await db.collection('donations').aggregate([
        { $match: { createdAt: { $gte: thirtyDaysAgo } } },
        { $group: { _id: "$category", count: { $sum: 1 } } }
      ]).toArray();

      // 2. Aggregate User Stats
      const userStats = await db.collection('users').aggregate([
        { $group: { _id: "$role", count: { $sum: 1 } } }
      ]).toArray();

      // 3. Get Top NGO Needs
      const ngosWithNeeds = await db.collection('users')
        .find({ role: 'ngo', 'ngoDetails.needs': { $exists: true } })
        .limit(10)
        .toArray();

      const needsList = ngosWithNeeds.flatMap(n => (n.ngoDetails.needs || []).map(nd => nd.category));
      const topNeeds = [...new Set(needsList)].slice(0, 5);

      if (!this.genAI) return { summary: "Database looks healthy. High activity in food and clothes." };

      const model = this.genAI.getGenerativeModel({ model: "gemini-2.0-flash" });
      
      const prompt = `Analyze this Daansetu platform data and provide a strategic summary for the Admin.
      
      DONATION TRENDS (Last 30 days):
      ${donationStats.map(s => `${s._id}: ${s.count} donations`).join(", ")}
      
      USER BASE:
      ${userStats.map(s => `${s._id}s: ${s.count}`).join(", ")}
      
      CURRENT TOP NGO NEEDS:
      ${topNeeds.join(", ")}
      
      Generate a JSON object with:
      - executiveSummary (2-3 sentences of overall health)
      - keyTrend (the most important shift you see)
      - recommendation (one specific action the admin should take)
      - predictedNeeds (which category will be in high demand next week?)
      
      Return ONLY the JSON object.`;

      const result = await model.generateContent(prompt);
      const response = await result.response;
      const text = response.text();
      const jsonMatch = text.match(/\{[\s\S]*\}/);
      
      if (jsonMatch) return JSON.parse(jsonMatch[0]);
      return { executiveSummary: "Platform activity is steady." };

    } catch (error) {
      console.error("AI Analytics Generation Error:", error);
      return { executiveSummary: "Error generating AI insights." };
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
