import { logError, logVerbose } from "helpers";
import { getMovieClubSuggestionDocRef } from "src/movieClubs/suggestions/suggestionHelpers";

export interface SuggestionMock {
  title: string;
  imageUrl: string;
  createdAt: number;
}

type SuggestionMockParams = Partial<SuggestionMock> & {
  movieClubId: string;
  userId: string;
};

export async function populateSuggestionData(
  params: SuggestionMockParams,
): Promise<SuggestionMock> {
  logVerbose("Populating suggestion data...");

  const suggestionData: SuggestionMock = {
    imageUrl: params.imageUrl || "Test Image Url",
    title: params.title || "Test Title",
    createdAt: Date.now(),
  };

  const suggestionRef = getMovieClubSuggestionDocRef(params.userId, params.movieClubId)
  try {
    await suggestionRef.set(suggestionData);
    logVerbose("suggestion data set");
  } catch (error) {
    logError("Error setting suggestion data:", error);
  }

  return suggestionData;
}
