
## Functions for contraints
# Contrainte spatiale pour les voisins Nord, Est, Ouest et Sud pour la case visitée
neighborhoodNEWS <- function(m, i, j){
  #Pour le Nord
  N <- tryCatch({
    m[i-1,j]
  }, error = function(err1){return(NA)})

  #Pour l'Est
  E <- tryCatch({
    m[i,j+1]
  }, error = function(err2){return(NA)})

  # Pour l'Ouest
  W <- tryCatch({
    m[i,j-1]
  }, error = function(err3){return(NA)})

  # Pour le Sud
  S <- tryCatch({
    m[i+1,j]
  }, error = function(err4){return(NA)})

  ret <- c(N,E,W,S)
  return(ret)

}

neighborhoodNS <- function(m, i, j){
  N <- tryCatch({
    m[i-1,j]
  }, error = function(err1){return(NA)})

  S <- tryCatch({
    m[i+1,j]
  }, error = function(err4){return(NA)})

  ret <- c(N,S)
  return(ret)
}

neighborhoodWE <- function(m, i, j){
  # for right neighboor
  E <- tryCatch({
    m[i,j+1]
  }, error = function(err2){return(NA)})

  # For left neighboor
  W <- tryCatch({
    m[i,j-1]
  }, error = function(err3){return(NA)})

  ret <- c(W,E)
  return(ret)
}

checkConstraints <- function(m, row, col, mode){
  if(mode == "NS"){
    neighbors <- neighborhoodNS(m,row,col)
  }else if(mode=="WE"){
    neighbors <- neighborhoodWE(m, row, col)
  }else if(mode=="NEWS"){
    neighbors <- neighborhoodNEWS(m, row, col)
  }
  return(neighbors)
}

## Functions to solve the choosen cell in the plate
resample <- function(x, ...) x[sample.int(length(x), ...)]


solveCell <- function(m, d, nb_gps, i, j, already_drawn, constraint){
  # we look at which individuals are neighbors of the current box
  neighbors <- checkConstraints(m, row=i, col=j, mode=constraint)

  # identify which group the neighbors belong to in order to obtain a reduced
  # list of possibilities of groups for the current cell to fill
  forbidden_groups <- unique(d$group[which(d$ind %in% neighbors)])
  possible_groups <- which(!1:nb_gps %in% forbidden_groups)
  if(length(possible_groups)==0){
    #there are no more possibilities
    return(1)
  }else{
    # only take in individuals belonging to the possible groups
    # and who are not in already_drawn
    possible_ind <- d$ind[which(d$group %in% possible_groups)]
    available_ind <- d$ind[which(d$ind %in% possible_ind & !(d$ind %in% already_drawn))]

    if(length(available_ind)==0){
      #there are no more possibilities
      return(1)
    }else{
      chosen_ind <- resample(available_ind,size=1)
      m[i,j] <- chosen_ind
      already_drawn <- c(already_drawn,chosen_ind)

    }
  }

  return(list("m" = m, "already_drawn" = already_drawn))
}


# parcours aléatoire de la matrice à remplir
# m est une matrice
# forbidden_cells est un vecteur contenant les coordonnées sous forme xy des cases
# interdites
# d est le dataframe fournit par l'utilisateur
# groups est le nombre de groupes distincts existant dans les données utilisateur
# constraint est le mode de contrainte de voisinnage choisi par l'utilisateur
randomWalk <- function(m, forbidden_cells, d, groups, constraint){
  visited <- c() # cases visitées - que ce soit interdites ou autorisées aux échantillons
  nb_lig <- dim(m)[1]
  nb_col <- dim(m)[2]
  ret = m
  placed = c() # échnatillons déjà tirés et placés
  # tant que toutes les cases n'ont pas été visitées
  while (length(visited)!=nrow(d) ) {
    i = sample(1:nb_lig, size = 1)
    j = sample(1:nb_col, size = 1)
    cell = as.numeric(paste(i,j,sep=""))
    # si la cellule choisie est dans visited OU si c'est une case interdite
    if(cell %in% visited || cell %in% forbidden_cells){
      next
      #sinon update visited et faire les tâches à faire avec la cell choisie
    }else{
      # mise à jour des cases visitées
      visited <- c(visited,cell)
      # uniformisation de plaque
      test <- solveCell(m=ret, d=d, nb_gps=groups, i=i, j=j, already_drawn = placed, constraint = constraint)

      if(class(test)=="numeric"){
        return(1)
      }else{

        ret <- test$m
        placed <- test$already_drawn
        # we look after the last placed element
        d[which(d$ind == placed[length(placed)]),]$Row <- i
        d[which(d$ind == placed[length(placed)]),]$Column <- j
      }
    }
  }
  return(ret)
}

# user_df est un dataframe contenant les colonnes [Sample.name,Group,Row,Column]
generatePlate <- function(user_df, nb_rows, nb_cols, df_forbidden, mod){
  nb_attempts = 1
  ret=1

  forbidden_wells <- as.vector(as.numeric(paste0(df_forbidden$Rows,df_forbidden$Columns, sep="")))

  while (ret==1) {
    mat = matrix(NA,nrow=r, ncol=c)
    ret <- randomWalk(m = mat,
                      forbidden_cells = forbidden_wells,
                      d = user_df,
                      groups = length(unique(user_df$group)),
                      constraint = mod
                      )

    if(class(ret)=="matrix"){
      return(list("result" = ret, "attempts" = nb_attempts))
    }
    print("we try again")
    nb_attempts = nb_attempts + 1
  }

}


# Permet de générer un nombre précis d'échantillons (effectifs) qui correspondent à des groupes
# ATTENTION à n'utiliser que si l'on doit tenir compte de groupes évidemment...
# En entrée
# dataset: dataframe contenant deux colonnes (individu et groupe)
# effectifs: vecteur contenant les effectifs pour chaque groupe existant dans le jeu de données
# En sortie
# res:
selectBioSamples  <- function(dataset, effectifs){
  group = 1
  res = c()
  for (effectif in effectifs) {
    g <- dataset[dataset$groupe==group,][sample(nrow(dataset[dataset$groupe==group,]),effectif),]
    res <- rbind(res,g)
    group <- group + 1
  }
  return(res)
}

# convertForbiddenStringIntoNumber <- function(forbidden_wells){
#   forbidden_wells <- unlist(strsplit(as.character(forbidden_wells), split=","))
#   forbidden <- c()
#   for(element in forbidden_wells){
#     xy = unlist(strsplit(element, split = "-"))
#     forbidden = c(forbidden,as.numeric(paste0(xy[1],xy[2])))
#   }
#   return(forbidden)
# }

# function that generates the plate according to its dimensions, the chosen
# spatial constraints, the number of different groups and the numbers for each
# group.
# platePreparation <- function(d, r, c, forbid_wells){
#   colnames(d) = c("ind","group")
#   mat = matrix(NA,nrow=r, ncol=c)
#   forbidden <- convertForbiddenStringIntoNumber(forbid_wells)
#
#   nb.groups = length(unique(d$group))
#   # number of samples per group
#   workforce = d %>%
#     group_by(group) %>%
#     summarise(n_distinct(ind))
#   data = selectBioSamples(d, workforce$`n_distinct(ind)` %/% 2)
#   plate <- generatePlate(m=mat, interdit=forbidden, d=data, groupes=nb.groups)
# }




