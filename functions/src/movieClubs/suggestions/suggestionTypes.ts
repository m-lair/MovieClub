export interface CreateMovieClubSuggestionData {
  userImage?: string;
  clubId: string;
  imdbId: string;
  userId: string;
  userName: string;
}

export interface DeleteMovieClubSuggestionData {
  movieClubId: string;
}