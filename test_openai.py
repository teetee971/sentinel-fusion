import openai

# Remplace "TA_CLE_API" par ta clé API OpenAI
openai.api_key = "TA_CLE_API"

response = openai.ChatCompletion.create(
    model="gpt-3.5-turbo",
    messages=[{"role": "user", "content": "Dis-moi quelque chose d'intéressant."}]
)

print(response['choices'][0]['message']['content'].strip())import openai

# Remplace "TA_CLE_API" par ta clé API OpenAI
openai.api_key = "TA_CLE_API"

response = openai.Completion.create(
  model="text-davinci-003",
  prompt="Dis-moi quelque chose d'intéressant.",
  max_tokens=50
)

print(response.choices[0].text.strip())
