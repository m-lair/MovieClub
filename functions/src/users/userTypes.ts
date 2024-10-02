import { firebaseAdmin } from "firestore";

export interface UserData {
  bio?: string;
  email: string;
  image?: string;
  name: string;
  createdAt?: string | firebaseAdmin.firestore.FieldValue;
}

export interface CreateUserWithEmailData extends UserData {
  password: string;
};

export interface CreateUserWithOAuthData extends UserData {
  signInProvider: string;
};

export interface UpdateUserData extends UserData {
  id: string;
}