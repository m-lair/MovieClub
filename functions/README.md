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
  email: "string@email.com",
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
  image?: "string/path",
  signInProvider?: "string"
}
```

### updateUserEmail

### deleteUser

## Movie Clubs

### createMovieClub

```
Params = {
  ownerId: "string",
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
  ownerId: "string",
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