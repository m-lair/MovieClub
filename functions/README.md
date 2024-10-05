# Project Setup

### Dependencies
- Firebase CLI: https://firebase.google.com/docs/cli
- Node: https://nodejs.org/en/download/package-manager
- Typescript: https://www.typescriptlang.org/download/

### Configure Firebase CLI

Copy service-account.json to functions/src/utilities
```
firebase login
firebase use <project-id>
```

### Run Locally


`Terminal #1`
```
cd functions
npm install
tsc --watch
```

`Terminal #2`
```
cd functions/lib
npm install
npm run serve
```

`Terminal #3`
```
cd functions
npm run test
```

# Functions

## Users

### createUserWithEmail

```
Params = {
  email: "string@email.com",
  name: "string",
  password: "string",
  bio?: "string",
  image?: "string/path"
}

Returns: 
200 - "uid string"
400 - code: "invalid-argument"
```

### createUserWithSignInProvider

```
Params = {
  name: "string",
  signInProvider: "string",
  bio?: "string",
  image?: "string/path"
}

Returns: 
200 - "uid string"
400 - code: "invalid-argument"
```

### updateUser

```
Params = {
  name?: "string",
  bio?: "string",
  image?: "string/path"
}
```

### updateUserEmail

### deleteUser

## Movie Clubs

### createMovieClub

```
Params = {
  ownerName: "string",
  name: "string",
  isPublic: boolean,
  timeInterval: "string",
  bannerUrl: "string/path"
}
```

### updateMovieClub

```
Params = {
  movieClubId: "string",
  ownerName?: "string",
  name?: "string",
  isPublic?: boolean,
  timeInterval?: "string",
  bannerUrl?: "string/path"
}
```

### deleteMovieClub

## Movies

### suggestMovie

### rotateMovie

## Comments

### postComment

```
Params = {
  movieClubId: "string",
  movieId: "string",
  text: "string",
  userId: "string",
  username: boolean
}

Returns:
200 - "commentId"
```

### deleteComment

```
Params = {
  movieClubId: "string",
  movieId: "string",
  commentId: "string",
}

Returns:
200 - "commentId"