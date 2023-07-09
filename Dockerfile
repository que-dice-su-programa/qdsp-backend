# ---- Build Stage ----
FROM elixir:1.15 AS builder

# Set environment variables for building the application
ENV MIX_ENV=prod \
    LANG=C.UTF-8

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force


# Create the application build directory
WORKDIR /app

# Copy over all the necessary application files and directories
COPY config ./config
COPY lib ./lib
COPY priv ./priv
COPY mix.exs .
COPY mix.lock .

# Fetch the application dependencies and build the application
RUN mix deps.get
RUN mix deps.compile
RUN mix release

# ---- Application Stage ----
FROM elixir:1.15 AS runtime

ENV LANG=C.UTF-8

# Copy over the build artifact from the previous step
COPY --from=builder /app/_build .
COPY priv/embeddings ./priv/embeddings

CMD ["./prod/rel/qdsp/bin/qdsp", "start"]
