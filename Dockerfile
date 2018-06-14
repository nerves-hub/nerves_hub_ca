FROM cfssl/cfssl:1.3.2 as cfssl
FROM elixir:1.6

ENV \
  LANG=C.UTF-8 \
  LC_ALL=en_US.UTF-8 \
  PATH="/app:${PATH}"

ADD . /app
WORKDIR /app

COPY --from=cfssl /go/bin/cfssl cfssl

RUN apt-get update -y -qq \
  && apt-get -qq -y install \
    locales \
  && export LANG=en_US.UTF-8 \
  && echo $LANG UTF-8 > /etc/locale.gen \
  && locale-gen \
  && update-locale LANG=$LANG
RUN mix local.hex --force && mix local.rebar --force
RUN mix deps.get
RUN mix compile

CMD ["mix", "run", "--no-halt"]
