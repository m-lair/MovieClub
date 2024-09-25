# Functions

## Users

### createUser

```
Params = {
  email: "string@email.com",
  name: "string",
  password?: "string",
  bio?: "string",
  image?: "string/path",
  signInProvider?: "string"
}

Returns: 
200 - "uid string"
400 - code: "invalid-argument"
```

### updateUser

```
Params = {
  email?: "string@email.com",
  name?: "string",
  bio?: "string",
  image?: "string/path",
  signInProvider?: "string"
}
```

## Movie Clubs

### createMovieClub

### updateMovieClub

## Movies

### suggestMovie

## Comments

### postComment

### deleteComment
