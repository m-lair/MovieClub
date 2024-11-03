export interface CreateMovieClubSuggestionData {
  imageUrl?: string;
  movieClubId: string;
  imdbId: string;
  title: string;
  username: string;
}

export interface DeleteMovieClubSuggestionData {
  movieClubId: string;
}