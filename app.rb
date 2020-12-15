require 'rubygems'
require "bundler/setup"
require 'sinatra'
require 'sinatra/reloader'
require 'sqlite3'
require 'sequel'


def db_initialize
  @db = SQLite3::Database.new 'barbershop.sqlite'
  @db.results_as_hash = true # включает возможность обращаться к полям таблицы по имени
end

def send_barbers? db, name # проверка на совпадение 
  db.execute('select * from barbers where name=?',[name]).length > 0
end

def seed_bareber db, barbers #наполнение таблицы
  barbers.each do |barber|
  db.execute 'insert into barbers (name) values(?)',barber if !send_barbers? @db,barber
  end  
end

# исполняется перед каждым запросом get/post
before do 
  db_initialize
  @table_barbers = @db.execute 'select * from barbers'
  @db.execute 'create table if not exists
              "users"(
                "id" INTEGER PRIMARY KEY AUTOINCREMENT,
                 "Username" TEXT,
                 "Barber" TEXT,
                 "Phone" TEXT,
                 "DataStamp" TEXT
              )'

end
# исполняется перед каждым запросом get/post


configure do
  enable :sessions

  db_initialize # обращение к функции подключения БД
  #создание таблицы если такая не существует

   @db.execute 'create table if not exists
              "barbers"(
                "id" INTEGER PRIMARY KEY AUTOINCREMENT,
                "name" TEXT
              )'


  seed_bareber @db, ['Mike','Mishel','Riky','Anton']
end

helpers do
  def username
    session[:identity] ? session[:identity] : 'Hello stranger'
  end
end

before '/secure/*' do
  unless session[:identity]
    session[:previous_url] = request.path
    @error = 'Sorry, you need to be logged in to visit ' + request.path
    halt erb(:login_form)
  end
end

get '/' do
  erb 'Can you handle a <a href="/secure/place">secret</a>?'
end

get '/about' do
  @error = "Eror 404"
  erb :about
end

get '/login/form' do
  erb :login_form
end
get '/visit' do
  erb :visit
end

post '/visit' do
  @specialname = params[:special_name]
  @username = params[:username]
  @phone = params[:phonenumber]
  @datetime = params[:datetime]



  hh = {:username => 'Введите имя', 
        :phonenumber => 'Введите номер телефона',
        :datetime => 'Введите дату и время'
  }
    @error = hh.select {|key,_| params[key] == ''}.values.join(', ')
   
    return erb :visit if @error != ''

    #db = db_initialize
    @db.execute 'INSERT INTO users (Username,Barber,Phone,DataStamp) values ( ?, ?, ?, ?)',[@username, @specialname, @phone, @datetime]
    #db.close
    erb "<h2>Спасибо! Вы записаны на дату #{@datetime} к мастеру #{@specialname}</h2>"
    end

get '/admin' do
  #@proverka = @db.execute 'SELECT count(*) FROM sqlite_master WHERE type="table" AND name="users"' #сделает выборку если таблица существует
  
  #@table_users = @db.execute 'SELECT * from users' if @proverka['count(*)'].to_i > 0

  @table_users = @db.execute 'SELECT * FROM users'
  erb :admin
end

post '/admin' do
   #db = db_initialize

   @db.execute 'DROP TABLE if exists users'
   erb :admin
end

get '/contacts' do
  erb :contacts
end

post '/contacts' do
 # require 'pony'
  @email = params[:email]
  @text = params[:text]
  Pony.mail(
    :to => "melnik.m@unm74.ru",
    :from => @email,

    :via => :smtp,
    :via_options => { 
      :address              => 'smtp.yandex.ru', 
      :port                 => '25', 
      :enable_starttls_auto => true, 
      :user_name            => 'melnik.m@unm74.ru', 
      :password             => 'J%#yesdu237', 
      :authentication       => :plain
    })

  erb :contacts
end

post '/login/attempt' do
  session[:identity] = params[:username]
  @passwd = params[:passwd]
  where_user_came_from = session[:previous_url] || '/'
  if @passwd == 'secret'
  redirect to where_user_came_from
  else
    erb 'Incorrect password click back inlogin <a href="/login/form">backkkk</a>'
  end
end

get '/logout' do
  session.delete(:identity)
  erb "<div class='alert alert-message'>Logged out</div>"
end

get '/secure/place' do
  erb 'This is a secret place that only <%=session[:identity]%> has access to!'
end
