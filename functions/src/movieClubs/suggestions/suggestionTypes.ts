export interface CreateMovieClubSuggestionData {
  userImage?: string;
  clubId: string;
  imdbId: string;
  userId: string;
  userName: string;
  createdAt?: Date;
}

export interface DeleteMovieClubSuggestionData {
  movieClubId: string;
}