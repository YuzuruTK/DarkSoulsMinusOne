file = open("minigames/termo/words_clear.txt")

other_file = open("minigames/termo/words.txt", "w")
count = 0
words = file.readlines()
for word in words:
    word = word.strip()
    if len(word) >= 4 and word.islower():
        other_file.write(word + "\n")
    print(f"{(count/len(words)) * 100:.2f} % ", end="\r")
    count += 1
file.close()
other_file.close()