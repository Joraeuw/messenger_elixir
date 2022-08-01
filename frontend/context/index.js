import React, { useState, createContext } from "react";

export const Context = createContext();

export const ContextProvider = (props) => {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");

  const value = {
    email,
    setEmail,
    password,
    setPassword,
  };

  return <Context.Provider value={value}>{props.children}</Context.Provider>;
};
