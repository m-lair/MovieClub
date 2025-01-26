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
  userId: string;
  userName: string;
  movieClubId: string;
}

export interface CreateMovieData extends MovieData {
  id: string;
}

export interface MovieLikeRequest {
  movieId: string;
  clubId: string;
}

export interface MovieReactionData {
  likes: number;
  likedBy: string[];
  dislikes: number;
  dislikedBy: string[]; 
}

export interface LikeMovieData {
  movieClubId: string;
  movieId: string;
  name: string;
  undo?: boolean;
}
