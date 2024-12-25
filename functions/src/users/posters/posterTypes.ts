export interface PosterData {
    imdbId: string;
    posterUrl: string;
    colorStr: string;
    clubId: string;
    clubName: string;
    collectedDate: Date;
}

export interface CollectPosterData extends PosterData {
    id: string;
}