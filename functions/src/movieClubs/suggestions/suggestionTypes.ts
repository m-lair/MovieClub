export interface CreateMovieClubSuggestionData {
  title: string;
  movieClubId: string;
  imageUrl: string;
}

export interface DeleteMovieClubSuggestionData {
  movieClubId: string;
}