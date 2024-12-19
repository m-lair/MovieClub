export interface MovieData {
  likes: number;
  dislikes: number;
  numCollected: number;
  status: "active" | "archived";
  startDate: Date;
  endDate: Date;
  numComments: number;
  imdbId: string;
  collectedBy: string[];
  likedBy: string[];
  dislikedBy: string[];
}

export interface CreateMovieData extends MovieData {
  id: string;
}

export interface MovieLikeRequest {
  movieId: string;
  clubId: string;
}