FROM ruby:2.3.3

# BƯỚC THẦN THÁNH: Ghi đè sạch repo cũ và tắt cơ chế kiểm tra khóa GPG hết hạn của năm 2020
RUN echo "deb http://archive.debian.org/debian jessie main" > /etc/apt/sources.list && \
    echo "deb http://archive.debian.org/debian-security jessie/updates main" >> /etc/apt/sources.list && \
    echo "Acquire::Check-Valid-Until \"false\";" > /etc/apt/apt.conf.d/70deb && \
    echo "APT::Get::AllowUnauthenticated \"true\";" >> /etc/apt/apt.conf.d/70deb

# Ép hệ thống cài đặt chấp nhận các gói không cần xác thực khóa cũ
RUN apt-get update -qq && apt-get install -y --allow-unauthenticated build-essential libpq-dev nodejs sqlite3 libsqlite3-dev

RUN mkdir /myapp
WORKDIR /myapp

ADD Gemfile /myapp/Gemfile
ADD Gemfile.lock /myapp/Gemfile.lock

RUN bundle install
ADD . /myapp