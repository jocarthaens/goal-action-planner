A custom implementation of GOAP (Goal-Oriented Action Plan) AI framework.

## Parts of GOAP AI framework
+ __GOAPPlanner__ -> the brain of the GOAP AI where it finds an action plan from its pool of GOAPAction children nodes that leads to its goal. It iterates through each GOAPAction node that leads to the goal state, starting from the current state, generating a collection of plans. These plans are then evaluated for the desired cost (least cost or highest cost, depending on selected option), and will be chosen as the action plan. The action plan is then executed until either the whole sequence of actions is performed successfully, or one of its actions failed. Regardless of result, the planner will then proceed to replan a new action plan based on its current goal state.
+ __GOAPAction__ -> action nodes that holds the action logic to be executed by its GOAPPlanner parent. It has a set of preconditions and effects that aids the planner in creating a sequence of actions that lead to the target goal state.

## Demo
 Included is a demo about an orc in a forest trying to fill its hunger by either gathering berries, hunting boars, or stealing the guarded taco, while trying to hide from satyrs if not equipped with a bonker. Its pool of actions will depend on what objects are within its surrounding area and if it is currently equipped with a bonker. The orc prioritizes sneaking for tacos, then hunting for boar meat, and foraging berries is its least priority. If the orc haven't found anything of interest within its vicinity, or if it is fully satiated, it will wander around for a while.

---
![goap](https://github.com/user-attachments/assets/290ad7cf-0812-4fd9-bce7-a57d67166872)
---
![goap2](https://github.com/user-attachments/assets/f326bba0-7eba-442b-b9d3-e8e771a5c0fb)
---
