export interface JoinMovieClubData {
  clubId: string;
  clubName: string;
  image?: string;
  userName: string;
}

export interface LeaveMovieClubData {
  clubId: string;
}