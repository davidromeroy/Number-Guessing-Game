#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Ask for username
echo "Enter your username:"
read USERNAME

# Search for the user in the database
USER_INFO=$($PSQL "SELECT user_id, games_played, best_game FROM users WHERE username='$USERNAME'")

# If the user does not exist
if [[ -z $USER_INFO ]]
then
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  # Insert new user
  INSERT_USER=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME')")
else
  # Retrieve user information
  IFS="|" read USER_ID GAMES_PLAYED BEST_GAME <<< "$USER_INFO"
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Generate a random secret number
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))

# Initialize guess counter
NUMBER_OF_GUESSES=0

# Function to handle guesses
while true
do
  echo "Guess the secret number between 1 and 1000:"
  read GUESS

  # Check if input is a number
  if ! [[ $GUESS =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
  else
    # Increment guess count
    NUMBER_OF_GUESSES=$((NUMBER_OF_GUESSES + 1))

    # Compare with the secret number
    if [[ $GUESS -lt $SECRET_NUMBER ]]
    then
      echo "It's higher than that, guess again:"
    elif [[ $GUESS -gt $SECRET_NUMBER ]]
    then
      echo "It's lower than that, guess again:"
    else
      echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"

      # Update user statistics
      if [[ -z $USER_INFO ]]
      then
        # Update games played and best game for a new user
        UPDATE_USER=$($PSQL "UPDATE users SET games_played = 1, best_game = $NUMBER_OF_GUESSES WHERE username='$USERNAME'")
      else
        # Update games played
        NEW_GAMES_PLAYED=$((GAMES_PLAYED + 1))
        # Update best game if necessary
        if [[ $NUMBER_OF_GUESSES -lt $BEST_GAME ]]
        then
          BEST_GAME=$NUMBER_OF_GUESSES
        fi
        UPDATE_USER=$($PSQL "UPDATE users SET games_played = $NEW_GAMES_PLAYED, best_game = $BEST_GAME WHERE username='$USERNAME'")
      fi
      break
    fi
  fi
done
