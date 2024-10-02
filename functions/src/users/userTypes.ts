import { firebaseAdmin } from "firestore";

export interface UserData {
  bio?: string;
  image?: string;
  name: string;
  createdAt?: string | firebaseAdmin.firestore.FieldValue;
}

export interface CreateUserWithEmailData extends UserData {
  email: string;
  password: string;
};

export interface CreateUserWithOAuthData extends UserData {
  email: string;
  signInProvider: string;
};

export interface UpdateUserData extends UserData {
  id: string;
}