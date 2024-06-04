/**
* Name: ABM for Hospital Building Evacuation 
* Authors: ABIL team
* Description: ABM for Hospital Building Evacuation 
* NDEX TERMS : Evacuation modeling, Agent Based Modeling, Intelligent Agents, Fire breakout, Hospital
building, Complex Systems Modeling, Model Simulation
*/

model evacuation_incendie

/* Insert your model definition here */
global
{

/* Les définitions globales des shapefile */
	file murs_shape_file <- shape_file("../includes/Muraille11.shp");
	file exit_shape_file <- shape_file("../includes/Exit11.shp");
	file obstacle_shapefile <- shape_file("../includes/obstacle.shp");
	file cadre_shape_file <- shape_file("../includes/Cadre.shp");
	file parcours_shape_file <- shape_file("../includes/localisation.shp");
	file passage_shape_file <-shape_file("../includes/passage.shp");
	geometry shape <- envelope(cadre_shape_file);
	graph graph_parcours;
	graph reseau_murs;

	/* Les définitions   globales des variables de l'agent people */
	int nb_people <- 50 min: 5 max: 300;
	float people_size <- 11.0;
	int people_puissance <- 20 min: 1 max: 100;
	float people_vitesse_init <- 2.5;
	float people_vitesse_max <- 3.9;
	int niv_effet_people <- rnd(people_puissance) + 1;
	int temps_parcours <- 0;
	bool depart <- false;
	point point_evacuation;
	float temps_evac_p<-0.0 #s;
    int a;
    int b; 
    int nb_malade <- 50 min: 5 max: 300;
	float malade_size <- 11.0;
	int malade_puissance <- 20 min: 1 max: 100;
	float malade_vitesse_init <- 2.0;
	float malade_vitesse_max <- 3.5;
	int niv_effet_malade <- rnd(malade_puissance) + 1;
	int temps_parcours_m <- 0;
	bool depart_m <- false;
	point point_evacuation_m;
	float temps_evac_m<-0.0 #s;
	
	/**  Les definitions globales des variables de l'agent feu*/
	point localisation_feu <-{rnd(200, 205), rnd(550, 555)};
	int feu_size <- 100 min: 1 max: 100;
	int nb_feu <- 1 min: 1 max: 5;
	float feu_vitesse <- 0.02 min: 0.001 max: 3.5;
	point feu_location;

	/**  Les definitions globales des variables de l'agent fumee*/
	int nb_fumee <- 0 min: 1 max: 1;
	float fumee_size <- 150.0 min: 1.0 max: 200.0;
	float fumee_vitesse <- 0.02 min: 0.01 max: 2.1;
	
	/**  Les definitions globales des variables et les actions */
	init
	{
		create cadre from: cadre_shape_file
		{
		}

		create exit from: exit_shape_file
		{
//			ask (cellule overlapping self) where not each.is_wall
//			{
//				is_exit <- true;
//			}

            ask cellule overlapping self
			{
				is_exit <- true;
			}

		}
		
        create passage from:passage_shape_file
        {
            ask cellule overlapping self
			{
				is_passage <- true;
			}	
        }
        
		create parcours from: parcours_shape_file
		{
			ask (cellule overlapping self) where not (each.is_wall and each.is_obstacle and each.is_exit)
			{
				is_free <- true;
			}

		}

		graph_parcours <- as_edge_graph(parcours);
		create murs from: murs_shape_file
		{
//			ask cellule overlapping self
//			{
//				is_wall <- true;
//			}
            ask cellule overlapping self where not (each.is_exit)
			{
				is_wall <- true;
			}

		}

		create obstacle from: obstacle_shapefile
		{
		}

		
		let passage_ok type: list of: parcours <- list(parcours);
		create feu number: 1
		{
			set location <- localisation_feu;
			create fumee number: 1
			{
				set location <- localisation_feu;
			}

		}

		parcours ma_localisation <- one_of(parcours);
		create people number: nb_people
		{
			location <- any_location_in(one_of(passage_ok));
			point_evacuation <- one_of(cellule where each.is_exit).location;
		}

		create malade number: nb_malade
		{
			location <- any_location_in(one_of(passage_ok));
			point_evacuation_m <- one_of(cellule where each.is_exit).location;
		}

	}

}

grid cellule width: 50 height: 50 neighbors: 8
{
	bool is_wall <- false;
	bool is_exit <- false;
	bool is_obstacle <- false;
	bool is_cadre <- false;
	bool is_free <- true;
	bool is_passage<-true;
	rgb color <- # white;
}

/** Definir les espece des agents crees*/

species people skills: [moving]
{
	int puissance <- rnd(people_puissance) + 10;
	float vitesse_people <- people_vitesse_init + rnd(rnd(people_vitesse_max) - rnd(people_vitesse_init));
	bool departx <- false;
	int people_rayon <- 200 min: 1 max: 300;
	int size <- rnd(people_size) + 8 as int;
	point point_evacuation <- nil;
	list<cellule> arrivee <- (cellule where each.is_exit);
	float temps_parcours <- 0.0#s;
	rgb people_color <- #purple;
	aspect base
	{
		draw pyramid(people_size) color: people_color;
		draw sphere(people_size / 2) at: { location.x, location.y, size } color: people_color;
		//draw circle(people_size) color:people_color;
	}

	reflex constater_fumer
	{
		list<fumee> voisins_fumee <- fumee at_distance (people_rayon);
		if (length(voisins_fumee) > 0)
		{
			ask voisins_fumee
			{
				depart <- true;
				set temps_parcours <- temps_parcours + 1;
			}

		}

	}

	reflex constater_feu
	{
		list<feu> voisins_feu <- feu at_distance (people_rayon);
		if (length(voisins_feu) > 0)
		{
			ask voisins_feu
			{
				depart <- true;
				set temps_parcours <- temps_parcours + 1;
			}

		}

	}

	reflex move 
	{
		
		
		reseau_murs<-as_edge_graph((murs));
		do goto target: point_evacuation speed: vitesse_people on:(cellule where not each.is_wall);
//		do follow path:nn;
        temps_evac_p<-temps_evac_p+1;
       
	}

    
    list<people>puissant<-people where (each.puissance >0);
    int nb_people_mort<-length (list (people) where (each.puissance <=0));
	int nb_people_vivant<-length (list (people) where (each.puissance >0));
	int a<-nb_people_mort;
	int b<-nb_people_vivant;
	
}


species malade skills:[moving]
{
	
    int puissance_malade <- rnd(malade_puissance) + 10;
	float vitesse_malade <- malade_vitesse_init + rnd(rnd(malade_vitesse_max) - rnd(malade_vitesse_init));
	bool depart_m <- false;
	int malade_rayon <- 200 min: 1 max: 300;
	int size <- rnd(malade_size) + 8 as int;
	point point_evacuation_m <- nil;
	list<cellule> arrivee <- (cellule where each.is_exit);
	float temps_parcours_m <- 0.0#s;
	rgb malade_color <- # blue;
	float malade_size <- 8.0;
	aspect base
	{ 
		draw triangle(malade_size) color: malade_color;
	}
	
	reflex constater_fumer
	{
		list<fumee> voisins_fumee <- fumee at_distance (malade_rayon);
		if (length(voisins_fumee) > 0)
		{
			ask voisins_fumee
			{
				depart_m <- true;
				set temps_parcours <- temps_parcours + 1;
			}

		}

	}

	reflex constater_feu
	{
		list<feu> voisins_feu <- feu at_distance (malade_rayon);
		if (length(voisins_feu) > 0)
		{
			ask voisins_feu
			{
				depart_m <- true;
				set temps_parcours_m <- temps_parcours_m + 1;
			}

		}

	}

    
	reflex move
	{
		do goto target: point_evacuation_m speed: vitesse_malade on: (cellule where not each.is_wall) recompute_path: false;
		temps_evac_m <- temps_evac_m + 1;
		
	}
	
	int nb_malade_mort<-length (list (malade) where (each.puissance_malade <=0));
	int nb_malade_vivant<-length (list (malade) where (each.puissance_malade >0));
	int c<-nb_malade_mort;
	int d<-nb_malade_vivant;
	

}
species feu skills:[moving]
{
	cadre c<-one_of (cadre);
	int size <- feu_size;
	float debuter <- feu_vitesse;
	float fume <- fumee_vitesse;
	float rayon <- 60.0;
	float rayon_s<-(rayon+rnd(0,2));
	point debut_feu <- [rayon - rnd(rayon * 2), rayon - rnd(rayon * 2)] as point;
	file icon_feu <- file("../images/fx.png");
	aspect defaut
	{
		draw icon_feu size: feu_size;
	}

	reflex se_propager when: (flip(debuter))
	{
		create species: feu number: 1
		{
			set location <- myself.location + debut_feu;
			do wander amplitude:180;
			
			feu_location <- location;
		}

	}

	reflex people_mourir
	{
		list<people> voisins_feu <- people at_distance (rayon_s);
		if (length(voisins_feu) > 0)
		{
			ask voisins_feu
			{
				if (self.location != point_evacuation)
				{
					self.puissance <- self.puissance - niv_effet_people;
					if (self.puissance < 1)
					{
						self.people_color <- # black;
						self.point_evacuation <- nil;
					}

				}

			}

		}

	}
	reflex malade_mourir
	{
		list<malade> voisins_feu <- malade at_distance (rayon_s);
		if (length(voisins_feu) > 0)
		{
			ask voisins_feu
			{
				if (self.location != point_evacuation)
				{
					self.puissance_malade <- self.puissance_malade - niv_effet_malade;
					if (self.puissance_malade< 1)
					{
						self.malade_color <- # black;
						self.point_evacuation_m <- nil;
					}

				}

			}

		}

	}
}

species fumee skills: [moving]
{
	float size_fumee <- fumee_size;
	float fume <- fumee_vitesse;
	file icon_fumee <- file("../images/smoke1.png");
	rgb color <- # black;
	float rayon <- 20.0;
	aspect defaut
	{
		draw icon_fumee size: size_fumee color: color;
	}

	reflex se_propager when: (flip(fume))
	{
		create species: fumee number: 1
		{
			set location <- feu_location;
			do wander amplitude: 180;
		}

	}

}



species parcours
{
	aspect default
	{
		draw shape color: # white;
	}

}

species cadre
{
	aspect default
	{
		draw shape color: # lavender;
	}
}

species murs
{
	aspect default
	{
		draw shape color: # black ;
	}

}

species exit
{
	aspect default
	{
		draw shape color: # red;
	}

}

species obstacle
{
	aspect default
	{
		draw shape color: # gray depth:10;
	}

}
species passage
{
	
}


/** les definitions des entrees et sorties du model */
experiment evacuation type: gui
{
	// parametre pour l'agent people
	parameter 'Nombre people: ' var:nb_people category:people;
	parameter 'Taille people: ' var:people_size category:people;
	parameter 'Puissance people: ' var:people_puissance category:people;
	parameter 'Vitesse initiale people: ' var:people_vitesse_init category:people;
	parameter 'Vitesse maximale people: ' var:people_vitesse_max category:people;
	// parametre pour l'agent malade
	parameter 'Nombre malade: ' var:nb_malade category:malade;
	parameter 'Taille malade: ' var:malade_size category:malade;
	parameter 'Puissance malade: ' var:malade_puissance category:malade;
	parameter 'Vitesse initiale malade: ' var:malade_vitesse_init category:malade;
	parameter 'Vitesse maximale malade: ' var:malade_vitesse_max category:malade;
	
	// parametre pour l'agent feu
	parameter 'Localisation feu: ' var:localisation_feu category:feu;
	parameter 'Vitesse feu:' var:feu_vitesse category:feu;
	
	output
	{
		display my_display refresh:every(1#s) 
		{
	
			
			species murs aspect: default;
			species parcours aspect: default;
			species exit aspect: default;
			species obstacle aspect: default;
			species fumee aspect: defaut;
			species feu aspect: defaut;
			species people aspect: base;
			species malade aspect:base;
		}
        display Graphique1 refresh:every(1#s){
        	chart "graphique_total" type:pie{
   			 data "nb_mort" value:((length (list (people) where (each.puissance <=0)))+(length (list (malade) where (each.puissance_malade <=0)))) color:#indigo;
   			 data "nb_vivant" value:((length (list (people) where (each.puissance >0)))+(length (list (malade) where (each.puissance_malade >0))))  color:#turquoise;
             
   			 }
        }
        display Graphique refresh:every (1#s) {
  		 
   		chart "Graphique_partiel" type:pie{
   			data "nb_people_mort" value:length (list (people) where (each.puissance <=0)) color:#navy;
             data "nb_malade_mort" value:length (list (malade) where (each.puissance_malade <=0)) color:#hotpink;
             data "nb_people_vivant" value:length (list (people) where (each.puissance >0) ) color:# seagreen;
             data "nb_malade_vivant" value: length (list (malade) where (each.puissance_malade >0)) color:# brown;
   		}	 
        }
        
       monitor Total_nombre_personne value: (nb_people+nb_malade);
       monitor les_vivants value: ((length (list (people) where (each.puissance >0)))+(length (list (malade) where (each.puissance_malade >0)))) refresh:every(1#s) ;    
       monitor les_morts value: ((length (list (people) where (each.puissance <=0)))+(length (list (malade) where (each.puissance_malade <=0)))) refresh:every(1#s) ;         
       monitor les_malades_vivants value: length (list (malade) where (each.puissance_malade >0));
       monitor les_malades_morts value:length (list (malade) where (each.puissance_malade <=0));
       monitor people_vivant value:length (list (people) where (each.puissance >0) );
       monitor people_mort value: length (list (people) where (each.puissance <=0));
       monitor temps_moyen_evacuation_en_seconde value: (((temps_evac_p/nb_people)+(temps_evac_m/nb_malade))/2);
//       monitor temps_moyen_evacuation_en_seconde value: (((temps_evac_p/nb_people))/2);
	}

}
