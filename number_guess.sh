#!/bin/bash

# psql interaction variable
PSQL="psql --username=freecodecamp --dbname=numbergame -t --no-align -c"

# Get random number
RN=32767
until [[ $RN -lt 32000 ]]
do
  # $RANDOM gives a number between 0-32767,
  # if I only count results up to 32000, it should
  # be the same chance for all numbers.
  RN=$RANDOM
done
RN=$((1 + $RN % 1000))

# testing with set value:
# RN=1

# get username, 22 char max
echo -e "Enter your username:"
read USERN

# check db for name
USERD=$($PSQL "SELECT uid, username, games_total, best_game FROM users WHERE username='$USERN'")

# if username not in db:
if [[ -z $USERD ]]
then
  # add user to db
  $PSQL "INSERT INTO users (username) VALUES ('$USERN')" >/dev/null
  USERD=$($PSQL "SELECT uid, username, games_total, best_game FROM users WHERE username='$USERN'")
  
  IFS="|" read U_ID USERN GAMEST BGAME <<< $USERD

  echo "Welcome, $USERN! It looks like this is your first time here."

# if username in db:
else
  IFS="|" read U_ID USERN GAMEST BGAME <<< $USERD

  echo "Welcome back, $USERN! You have played $GAMEST games, and your best game took $BGAME guesses."
fi

# validation function
# first argument is the user value to validate
validate_guess () {
  # if not a number
  re='^[0-9]+$'
  if ! [[ $1 =~ $re ]] ; 
  then
    return 1
  fi
  # if number
  return 0
}

# get initial user guess
echo -e "\nGuess the secret number between 1 and 1000:"
read GUESS

# main game loop
LOOPCOUNT=1
until [[ $GUESS -eq $RN ]]
do
  # add to loop count
  ((LOOPCOUNT++))

  # if not a valid number
  if ! $(validate_guess $GUESS)
  then
    echo -e "\nThat is not an integer, guess again:"
    read GUESS
    continue

  # guess too high
  elif [[ $GUESS -gt $RN ]]
  then
    echo -e "\nIt's lower than that, guess again:"
    read GUESS
    continue

  # guess too low
  elif [[ $GUESS -lt $RN ]]
  then
    echo -e "\nIt's higher than that, guess again:"
    read GUESS
    continue
  fi

done

# guess correct:
echo "You guessed it in $LOOPCOUNT tries. The secret number was $RN. Nice job!"

# save to games_total
((GAMEST++))
$PSQL "UPDATE users SET games_total=$GAMEST WHERE uid=$U_ID" >/dev/null

# if no best_game, save
if [[ -z $BGAME ]]
then
  $PSQL "UPDATE users SET best_game=$LOOPCOUNT WHERE uid=$U_ID" >/dev/null

# or old best_game is worse, save
elif [[ $LOOPCOUNT -lt $BGAME ]]
then
  $PSQL "UPDATE users SET best_game=$LOOPCOUNT WHERE uid=$U_ID" >/dev/null
fi