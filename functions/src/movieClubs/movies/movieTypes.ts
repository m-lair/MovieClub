export interface MovieData {
    likes: number;
    dislikes: number;
    numCollected: number;
    status: "active" | "archived";
    startDate: Date;
    endDate: Date;
    numComments: number;
    imdbId: string;
}

export interface CreateMovieData extends MovieData {
    id: string;
}