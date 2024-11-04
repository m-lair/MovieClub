export interface CreateMovieClubSuggestionData {
  userImage?: string;
  clubId: string;
  imdbId: string;
  userId: string;
  username: string;
}

export interface DeleteMovieClubSuggestionData {
  movieClubId: string;
}