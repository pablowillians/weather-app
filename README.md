# Weather App

This is a weather app that allows you to search for a location and get the current weather and forecast for that location.

## Documentation

Access the documentation at [https://pablowillians.github.io/weather-app/](https://pablowillians.github.io/weather-app/).

## Features

- [ ] Search for a location and get the current weather and forecast for that location.

## Technologies

- Ruby 3.4.5
- Ruby on Rails 8.1.2
- RSpec 8.0
- Dotenv

## Setup

Before running the application, you need to create a Google Places API key. Go to [Google Cloud Console](https://console.cloud.google.com/google/maps-apis/credentials) and create a new API key.

### Steps

1. Clone the [repository](https://github.com/pablowillians/weather-app).
2. Copy the `.env.example` file to `.env` and add your Google Places API key
3. If you are running for the first time, run `bin/setup` to install dependencies and set up the database.
4. Run `bin/dev` to start the development server
5. Visit `http://localhost:3000` in your browser

## Running Tests

Run `bin/rspec` to run the tests

## Generating Documentation

Documentation is written in **Markdown** in the code comments and in this README. Run `bin/doc` to generate the static RDoc site in `doc/rdoc` (and open it in the browser). The same docs are deployed to GitHub Pages on push to `main`.
