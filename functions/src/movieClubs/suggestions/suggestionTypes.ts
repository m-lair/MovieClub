export interface CreateMovieClubSuggestionData {
  imageUrl?: string;
  movieClubId: string;
  title: string;
  username: string;
}

export interface DeleteMovieClubSuggestionData {
  movieClubId: string;
}