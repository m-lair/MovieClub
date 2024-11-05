export interface CreateMovieClubSuggestionData {
  userImage?: string;
  clubId: string;
  imdbId: string;
  userId: string;
  userName: string;
  createdAt?: number;
}

export interface DeleteMovieClubSuggestionData {
  movieClubId: string;
}