import * as functions from "firebase-functions";
import { firestore } from "firestore";
import {
  handleCatchHttpsError,
  logVerbose,
  verifyAuth,
} from "helpers";
import { CallableRequest } from "firebase-functions/https";
import { MOVIE_CLUBS } from "src/utilities/collectionNames";

/**
 * Cloud function to validate movie club names
 * Performs checks for:
 * - Profanity/inappropriate content using custom word list
 * - Uniqueness (no duplicate club names)
 * - Length and character validation
 */

// Hard-coded basic profanity list as fallback in case file reading fails
const basicProfanityList = [
  "anal", "anus", "ass", "bastard", "bitch", "boob", "cock", "cunt", "dick", "dildo", 
  "fag", "fuck", "nigger", "penis", "porn", "pussy", "sex", "shit", "slut", "tit", 
  "vagina", "whore", "xxx"
];

// File system utilities for reading the swear words file
const fs = require('fs');
const path = require('path');

// Read custom swear words from file with better error handling
function getCustomSwearWords(): string[] {
  try {
    // Try multiple possible paths to find the swear words file
    const possiblePaths = [
      path.join(__dirname, 'swearWords.txt'),
      path.join(__dirname, './swearWords.txt'),
      path.join(__dirname, '../moderation/swearWords.txt')
    ];
    
    for (const swearWordsPath of possiblePaths) {
      if (fs.existsSync(swearWordsPath)) {
        console.log(`Found swear words file at: ${swearWordsPath}`);
        const content = fs.readFileSync(swearWordsPath, 'utf8');
        const words = content.split('\n')
          .map((word: string) => word.trim().toLowerCase())
          .filter((word: string) => word.length > 0);
        
        console.log(`Loaded ${words.length} words from profanity list`);
        return words;
      }
    }
    
    // If file not found, log error and use basic list
    console.error('Could not find swearWords.txt file in any expected location');
    console.log(`Using fallback list with ${basicProfanityList.length} words`);
    return basicProfanityList;
  } catch (error) {
    console.error('Error reading swear words file:', error);
    console.log(`Using fallback list with ${basicProfanityList.length} words`);
    return basicProfanityList;
  }
}

// Custom profanity check function
function containsProfanity(text: string, wordList: string[]): boolean {
  const lowerText = text.toLowerCase();
  
  // Check for exact matches
  for (const word of wordList) {
    if (lowerText.includes(word)) {
      console.log(`Profanity detected: "${word}" in "${text}"`);
      return true;
    }
  }
  
  // Check for words with spaces or special characters in between
  const textWithoutSpecialChars = lowerText.replace(/[^a-z0-9]/g, '');
  for (const word of wordList) {
    const wordWithoutSpecialChars = word.replace(/[^a-z0-9]/g, '');
    if (wordWithoutSpecialChars.length > 2 && textWithoutSpecialChars.includes(wordWithoutSpecialChars)) {
      console.log(`Obfuscated profanity detected: "${word}" in "${text}"`);
      return true;
    }
  }
  
  return false;
}

// Define the request and response types
interface ValidateClubNameRequest {
  name: string;
}

exports.validateClubName = functions.https.onCall(
  async (request: CallableRequest<ValidateClubNameRequest>) => {
    try {
      const { data, auth } = request;
      
      // Verify authentication
      verifyAuth(auth);
      
      const name = data.name;
      
      // Basic validation
      if (!name || typeof name !== 'string') {
        return {
          success: false,
          message: 'Club name must be provided as a string.'
        };
      }

      const trimmedName = name.trim();
      
      // Length validation
      if (trimmedName.length < 3) {
        return {
          success: false,
          message: 'Club name must be at least 3 characters.'
        };
      }
      
      if (trimmedName.length > 30) {
        return {
          success: false,
          message: 'Club name cannot be longer than 30 characters.'
        };
      }
      
      // Character validation
      const validCharRegex = /^[a-zA-Z0-9 \-_&():,.!?]+$/;
      if (!validCharRegex.test(trimmedName)) {
        return {
          success: false,
          message: 'Club name contains invalid characters.'
        };
      }
      
      // Custom profanity check using our word list
      logVerbose("Checking for profanity...");
      const customSwearWords = getCustomSwearWords();
      if (containsProfanity(trimmedName, customSwearWords)) {
        return {
          success: false,
          message: 'Club name contains inappropriate content.'
        };
      }
      
      // Check for uniqueness
      logVerbose("Checking for name uniqueness...");
      const clubsSnapshot = await firestore.collection(MOVIE_CLUBS)
        .where('name', '==', trimmedName)
        .limit(1)
        .get();
      
      if (!clubsSnapshot.empty) {
        return {
          success: false,
          message: 'A club with this name already exists.'
        };
      }
      
      // All validation passed
      return {
        success: true
      };
    } catch (error) {
      return handleCatchHttpsError("Error validating club name:", error);
    }
  }
); 